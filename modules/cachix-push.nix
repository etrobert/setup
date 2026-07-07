_: {
  flake.nixosModules.cachix-push =
    { config, pkgs, ... }:
    let
      # Push only locally-built paths to soft-nix. A Nix post-build hook fires
      # solely for paths the daemon builds, so substituted paths (already on
      # cache.nixos.org) are never re-uploaded, and non-build store additions
      # (e.g. source-tree copies) are never pushed at all.
      pushHook = pkgs.writeShellScript "cachix-post-build-push" ''
        set -eu
        set -f         # disable globbing
        export IFS=' ' # $OUT_PATHS is space-separated
        export HOME=/root

        CACHIX_AUTH_TOKEN="$(< ${config.age.secrets.cachix-token.path})"
        export CACHIX_AUTH_TOKEN

        ${pkgs.cachix}/bin/cachix push soft-nix $OUT_PATHS \
          || echo "cachix push failed ($?); continuing" >&2
      '';
    in
    {
      age.secrets.cachix-token.file = ../secrets/cachix-token.age;

      nix.settings.post-build-hook = "${pushHook}";
    };
}
