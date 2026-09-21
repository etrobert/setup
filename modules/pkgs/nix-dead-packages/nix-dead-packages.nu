# Flags declared packages that end up in no host system derivation.
#
# Takes the union of every host toplevel derivation closure and checks each
# package against it. Read-only — unlike the module sweep there is nothing to
# poison, so it reads the working tree directly with no worktree.

cd (git rev-parse --show-toplevel)

# Deliberately never installed: invoked with `nix run`. Listed rather than
# silently skipped, and reported below if one ever becomes installed.
const allow = [
  flake-input-table # .github/workflows/update-flake.yml
  nix-dead-packages # .github/workflows/checks.yml
]

# nix prints its own error as it happens; this adds which attribute it was.
def nix-eval [attr: string, apply: string] {
  try {
    ^nix eval --json --accept-flake-config $attr --apply $apply | from json
  } catch {
    error make { msg: $"evaluating ($attr) failed" }
  }
}

def names [attr: string]: nothing -> list<string> {
  nix-eval $attr builtins.attrNames
}

def host-closure [host: string]: nothing -> list<string> {
  let drv = nix-eval $".#($host)" "host: host.config.system.build.toplevel.drvPath"
  ^nix-store --query --requisites $drv | lines
}

# tryEval so a package that cannot evaluate for one system does not abort the
# run; a package that evaluates for no system has no drv line and is reported.
def package-drvs [system: string]: nothing -> table<name: string, drv: string> {
  nix-eval $".#packages.($system)" '
    ps: builtins.mapAttrs (
      _: p: let r = builtins.tryEval (p.drvPath or null); in if r.success then r.value else null
    ) ps
  ' | transpose name drv | where drv != null
}

let hosts = [nixosConfigurations darwinConfigurations] | each {|output|
  names $".#($output)" | each {|host| $"($output).($host)" }
} | flatten
let systems = names .#packages

# Every evaluation runs concurrently: each host instantiates its own nixpkgs,
# so there is nothing to share and the run is bounded by the slowest one.
print --stderr "collecting host system closures and package derivations..."
let jobs = (
  ($hosts | each {|host| {|| host-closure $host } })
  ++ ($systems | each {|system| {|| package-drvs $system } })
)
let results = $jobs | par-each --keep-order {|job| do $job }
let closure = $results | first ($hosts | length) | flatten
let packages = $results | skip ($hosts | length) | flatten

let all = $packages | get name | uniq
let used = $packages | where drv in $closure | get name | uniq
let unused = $all | where $it not-in $used

let reports = [
  [title names];
  ["in no host system derivation:" ($unused | where $it not-in $allow)]
  ["allowlisted but now installed — drop from the allowlist:" ($used | where $it in $allow)]
  # Deleting a package would otherwise leave its allowlist entry behind
  # unnoticed, since a name that is in neither `used` nor `unused` matches
  # nothing above.
  ["allowlisted but no such package — drop from the allowlist:" ($allow | where $it not-in $all)]
] | where ($it.names | is-not-empty)

for report in $reports {
  print $report.title
  print ($report.names | sort | each {|name| $"  ($name)" } | str join "\n")
}

if ($reports | is-empty) {
  print "every package outside the allowlist reaches a host."
  exit 0
}
exit 1
