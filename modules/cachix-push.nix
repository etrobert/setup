_: {
  flake.nixosModules.cachix-push =
    {
      config,
      lib,
      pkgs,
      ...
    }:
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
          # separate arguments (IFS) without glob-expanding any of them (noglob).
          set -o noglob
          export IFS=' '

          CACHIX_AUTH_TOKEN="$(< ${config.age.secrets.cachix-token.path})"
          export CACHIX_AUTH_TOKEN

          # shellcheck disable=SC2086 # intentional word-splitting of $OUT_PATHS
          cachix push soft-nix $OUT_PATHS
        '';
      };
    in
    {
      age.secrets.cachix-token.file = ../secrets/cachix-token.age;

      nix.settings.post-build-hook = lib.getExe pushHook;
    };
}
