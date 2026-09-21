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

# One JSON line per attribute; an attribute that fails to evaluate carries
# `error` instead of `drvPath` and does not abort the run.
# --select: a host is not a derivation, so map it to its toplevel
# --force-recurse: the per-system package sets lack recurseForDerivations
# --workers: one per host plus one; more only slow the longest host's eval
echo "evaluating host toplevels and packages..." >&2
nix-eval-jobs --accept-flake-config --flake . --force-recurse --workers 6 \
  --select '
    flake:
    let
      toplevel = builtins.mapAttrs (_: host: host.config.system.build.toplevel);
    in
    {
      hosts = toplevel flake.outputs.nixosConfigurations // toplevel flake.outputs.darwinConfigurations;
      packages = flake.outputs.packages;
    }
  ' >"$scratch/jobs"

jq --raw-output 'select(.attrPath[0] == "hosts" and .error) | "host \(.attrPath[1]) failed to evaluate:\n\(.error)"' \
  "$scratch/jobs" >"$scratch/host-errors"
if [ -s "$scratch/host-errors" ]; then
  cat "$scratch/host-errors" >&2
  exit 1
fi

jq --raw-output 'select(.attrPath[0] == "hosts") | .drvPath' "$scratch/jobs" |
  xargs nix-store --query --requisites | sort --unique >"$scratch/closure"

jq --raw-output 'select(.attrPath[0] == "packages" and .drvPath) | "\(.attrPath[2]) \(.drvPath)"' \
  "$scratch/jobs" | sort --unique >"$scratch/packages"

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
