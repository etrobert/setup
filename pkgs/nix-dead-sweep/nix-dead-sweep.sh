# Finds flake modules that no host imports.
#
# Poisons each declared flake.{nixos,darwin}Modules.<name> with a throw in turn
# and evaluates every host: a host importing it fails, and if none fail the
# module is unused. Being evaluation-based it sees through indirection a grep
# cannot follow, such as `imports = with self.nixosModules; [ ... ]`.

cd "$(git rev-parse --show-toplevel)"

scratch=$(mktemp --directory)
worktree=$scratch/tree
trap 'git worktree remove --force "$worktree" 2>/dev/null; rm --recursive --force "$scratch"' EXIT
git worktree add --detach --quiet "$worktree" HEAD
cd "$worktree"

# Tracked, because flakes ignore untracked files. Added once; later iterations
# overwrite it and the dirty tree is picked up.
probe=modules/zz-nix-dead-sweep.nix
echo '_: { }' >"$probe"
git add "$probe"

names() {
  nix eval --json --accept-flake-config ".#$1Modules" --apply builtins.attrNames |
    jq --raw-output '.[]'
}

# stateVersion forces the whole module list without building a system, so an
# imported poison throws in ~300ms rather than ~6s.
evaluates() {
  # --json, not --raw: stateVersion is a string on NixOS but an integer on darwin.
  nix eval --json --accept-flake-config \
    ".#$1Configurations.$2.config.system.stateVersion" >/dev/null 2>&1
}

mapfile -t nixos_hosts < <(nix eval --json --accept-flake-config \
  .#nixosConfigurations --apply builtins.attrNames | jq --raw-output '.[]')
mapfile -t darwin_hosts < <(nix eval --json --accept-flake-config \
  .#darwinConfigurations --apply builtins.attrNames | jq --raw-output '.[]')

# Without this a host broken at HEAD would make every module look imported and
# the sweep would report nothing at all.
for host in "${nixos_hosts[@]}"; do
  evaluates nixos "$host" ||
    {
      echo "$host does not evaluate at HEAD — fix that first" >&2
      exit 2
    }
done
for host in "${darwin_hosts[@]}"; do
  evaluates darwin "$host" ||
    {
      echo "$host does not evaluate at HEAD — fix that first" >&2
      exit 2
    }
done

unused=()
for kind in nixos darwin; do
  if [ "$kind" = nixos ]; then
    hosts=("${nixos_hosts[@]}")
  else
    hosts=("${darwin_hosts[@]}")
  fi

  for name in $(names "$kind"); do
    printf '{ lib, ... }: { flake.%sModules.%s = lib.mkForce (throw "unused"); }\n' \
      "$kind" "$name" >"$probe"

    imported=false
    for host in "${hosts[@]}"; do
      evaluates "$kind" "$host" || {
        imported=true
        break
      }
    done

    if [ "$imported" = true ]; then
      printf '  imported  %sModules.%s\n' "$kind" "$name" >&2
    else
      printf '  UNUSED    %sModules.%s\n' "$kind" "$name" >&2
      unused+=("${kind}Modules.$name")
    fi
  done
done

echo
if [ ${#unused[@]} -eq 0 ]; then
  echo "every declared module is imported by a host."
else
  echo "unused — no host imports these:"
  printf '  %s\n' "${unused[@]}"
  exit 1
fi
