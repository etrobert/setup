# Flags declared flake modules that no host imports.
#
# Reads each host's module graph — the tree of modules that took part in
# evaluation — and matches the provenance flake-parts stamps onto every node it
# contributes: "<flake source>/flake.nix#nixosModules.<name>". Nothing is
# poisoned, mutated or evaluated twice, so this reads the working tree directly.

cd "$(git rev-parse --show-toplevel)"

scratch=$(mktemp --directory)
trap 'rm --recursive --force "$scratch"' EXIT

attrs() {
  nix eval --json --accept-flake-config ".#$1" --apply builtins.attrNames |
    jq --raw-output '.[]'
}

# Anchored to this flake's own source path: input flakes stamp their modules the
# same way, and at least one exports a `nixosModules.default` that would
# otherwise be counted as ours.
root=$(nix flake metadata --json | jq --raw-output .path)
graph='
  g:
  let
    walk =
      n:
      [ (builtins.unsafeDiscardStringContext (toString n.file)) ]
      ++ builtins.concatLists (map walk (n.imports or [ ]));
    stamped = builtins.filter (m: m != null) (
      map (builtins.match "@ROOT@/flake\\.nix#((nixos|darwin)Modules\\..+)") (
        builtins.concatLists (map walk (builtins.filter (n: !n.disabled) g))
      )
    );
  in
  builtins.attrNames (builtins.groupBy builtins.head stamped)
'

: > "$scratch/used"
for output in nixosConfigurations darwinConfigurations; do
  for host in $(attrs "$output"); do
    mapfile -t found < <(
      nix eval --json --accept-flake-config ".#$output.$host.graph" \
        --apply "${graph//@ROOT@/$root}" | jq --raw-output '.[]'
    )
    # The stamp is a flake-parts convention, not a guarantee. Were the format to
    # change, the match would return nothing and every module would look unused,
    # so an empty host is a broken sweep rather than a finding.
    if [ ${#found[@]} -eq 0 ]; then
      echo "$host: no modules matched — has the flake-parts provenance stamp changed?" >&2
      exit 2
    fi
    printf '  %-6s %s modules\n' "$host" "${#found[@]}" >&2
    printf '%s\n' "${found[@]}" >> "$scratch/used"
  done
done

sort --unique "$scratch/used" --output "$scratch/used"
{ attrs nixosModules | sed 's/^/nixosModules./'
  attrs darwinModules | sed 's/^/darwinModules./'; } | sort --unique > "$scratch/declared"
comm -23 "$scratch/declared" "$scratch/used" > "$scratch/unused"

echo
if [ -s "$scratch/unused" ]; then
  echo "unused — no host imports these:"
  sed 's/^/  /' "$scratch/unused"
  exit 1
fi
echo "every declared module is imported by a host."
