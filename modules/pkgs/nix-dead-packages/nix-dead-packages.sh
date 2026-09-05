# Flags declared packages that end up in no host system derivation.
#
# Takes the union of every host toplevel derivation closure and checks each
# package against it. Read-only — unlike the module sweep there is nothing to
# poison, so it reads the working tree directly with no worktree.

cd "$(git rev-parse --show-toplevel)"

# Deliberately never installed: invoked with `nix run`. Listed rather than
# silently skipped, and reported below if one ever becomes installed.
allow=(
  flake-input-table # .github/workflows/update-flake.yml
  nix-dead-packages # .github/workflows/checks.yml
)

scratch=$(mktemp --directory)
trap 'rm --recursive --force "$scratch"' EXIT

names() {
  nix eval --json --accept-flake-config "$1" --apply builtins.attrNames |
    jq --raw-output '.[]'
}

# Every eval below is independent and nix is single-threaded, so running them
# together costs the slowest rather than the sum. eval-cache off because
# concurrent processes otherwise contend on its SQLite file, and each is a
# different attribute so none of them would hit the cache anyway.
echo "collecting host system closures and package derivations..." >&2

pids=()
for output in nixosConfigurations darwinConfigurations; do
  for host in $(names ".#$output"); do
    {
      drv=$(nix eval --raw --accept-flake-config --option eval-cache false \
        ".#$output.$host.config.system.build.toplevel.drvPath")
      nix-store --query --requisites "$drv"
    } >"$scratch/closure.$host" &
    pids+=($!)
  done
done

# tryEval so a package that cannot evaluate for one system does not abort the
# run; a package that evaluates for no system has no drv line and is reported.
{
  nix eval --json --accept-flake-config --option eval-cache false .#packages --apply \
    'ss: builtins.mapAttrs (
       _: ps: builtins.mapAttrs (
         _: p: let r = builtins.tryEval (p.drvPath or null); in if r.success then r.value else null
       ) ps
     ) ss' |
    jq --raw-output 'to_entries[] | .value | to_entries[]
                     | select(.value != null) | "\(.key) \(.value)"'
} >"$scratch/packages" &
pids+=($!)

for pid in "${pids[@]}"; do wait "$pid"; done

# A host whose eval failed would contribute nothing and make every package look
# unreferenced, so an empty closure is a broken run rather than a finding.
for file in "$scratch"/closure.*; do
  if [ ! -s "$file" ]; then
    echo "empty system closure for ${file##*closure.} — did its evaluation fail?" >&2
    exit 2
  fi
done
cat "$scratch"/closure.* | sort --unique >"$scratch/closure"
sort --unique "$scratch/packages" --output "$scratch/packages"

cut --delimiter=' ' --fields=1 "$scratch/packages" | sort --unique >"$scratch/all"
awk 'NR == FNR { closure[$0]; next } ($2 in closure) { print $1 }' \
  "$scratch/closure" "$scratch/packages" | sort --unique >"$scratch/used"

comm -23 "$scratch/all" "$scratch/used" >"$scratch/unused"
printf '%s\n' "${allow[@]}" | sort --unique >"$scratch/allow"
comm -23 "$scratch/unused" "$scratch/allow" >"$scratch/flagged"
comm -12 "$scratch/used" "$scratch/allow" >"$scratch/stale"
# Deleting a package would otherwise leave its allowlist entry behind unnoticed,
# since a name that is in neither `used` nor `unused` matches nothing above.
comm -23 "$scratch/allow" "$scratch/all" >"$scratch/gone"

status=0

if [ -s "$scratch/flagged" ]; then
  echo "in no host system derivation:"
  awk '{ print "  " $0 }' "$scratch/flagged"
  status=1
fi

if [ -s "$scratch/stale" ]; then
  echo "allowlisted but now installed — drop from the allowlist:"
  awk '{ print "  " $0 }' "$scratch/stale"
  status=1
fi

if [ -s "$scratch/gone" ]; then
  echo "allowlisted but no such package — drop from the allowlist:"
  awk '{ print "  " $0 }' "$scratch/gone"
  status=1
fi

if [ "$status" -eq 0 ]; then
  echo "every package outside the allowlist reaches a host."
fi

exit "$status"
