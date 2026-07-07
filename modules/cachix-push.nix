_: {
  flake.nixosModules.cachix-push =
    { config, pkgs, ... }:
    let
      # Push only locally-built paths to soft-nix. A Nix post-build hook fires
      # solely for paths the daemon builds, so substituted paths (already on
      # cache.nixos.org) are never re-uploaded, and non-build store additions
      # (e.g. source-tree copies) are never pushed at all.
      pushHook = pkgs.writeShellApplication {
        name = "cachix-post-build-push";
        runtimeInputs = [ pkgs.cachix ];
        inheritPath = false;

        text = ''
          # $OUT_PATHS is a space-separated list of paths; split it into
          # separate arguments (IFS) without glob-expanding any of them (set -f).
          set -f
          export IFS=' '

          # The daemon runs the hook with no HOME; give cachix a writable one.
          export HOME=/root

          CACHIX_AUTH_TOKEN="$(< ${config.age.secrets.cachix-token.path})"
          export CACHIX_AUTH_TOKEN

          # A non-zero post-build hook fails the build, so keep a failed push
          # (e.g. a cachix 502) from breaking nixos-rebuild or CI.
          # shellcheck disable=SC2086 # intentional word-splitting of $OUT_PATHS
          cachix push soft-nix $OUT_PATHS \
            || echo "cachix push failed ($?); continuing" >&2
        '';
      };
    in
    {
      age.secrets.cachix-token.file = ../secrets/cachix-token.age;

      nix.settings.post-build-hook = "${pushHook}/bin/cachix-post-build-push";
    };
}
