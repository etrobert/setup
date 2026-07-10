_: {
  flake.nixosModules.cachix-push =
    {
      self,
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (pkgs.stdenv.hostPlatform) system;
      inherit (self.packages.${system}) ntfy-wrapped;

      # Push only locally-built paths to soft-nix. A Nix post-build hook fires
      # solely for paths the daemon builds, so substituted paths (already on
      # cache.nixos.org) are never re-uploaded, and non-build store additions
      # (e.g. source-tree copies) are never pushed at all.
      pushHook = pkgs.writeShellApplication {
        name = "cachix-post-build-push";

        runtimeInputs = [
          pkgs.cachix
          pkgs.coreutils
          pkgs.gnugrep
          ntfy-wrapped
        ];

        inheritPath = false;

        text = ''
          # Skip non-substitutable paths: they can never be fetched from a cache
          # (so pushing is useless) and each drags its full closure. Only such
          # .drvs carry the ("allowSubstitutes","") literal.
          if grep --quiet '"allowSubstitutes",""' "$DRV_PATH"; then
            exit 0
          fi

          # $OUT_PATHS is a space-separated list of paths; split it into
          # separate arguments (IFS) without glob-expanding any of them (noglob).
          set -o noglob
          export IFS=' '

          CACHIX_AUTH_TOKEN="$(< ${config.age.secrets.cachix-token.path})"
          export CACHIX_AUTH_TOKEN

          # Bounded and non-fatal: this hook blocks `nix build`, and main CI
          # never cancels, so a stalled or misconfigured cache must never wedge
          # or fail a build. cachix retries transient 5xx/429 with a bounded
          # backoff but does NOT bound a stalled-open connection, so `timeout`
          # is the outer stop. Any non-zero exit — a fast-fatal 401/404 (bad
          # token, wrong cache name) or a timed-out stall — pings ntfy, so a
          # broken or misconfigured cache stays visible instead of silent.
          # shellcheck disable=SC2086 # intentional word-splitting of $OUT_PATHS
          if ! timeout 180 cachix push soft-nix $OUT_PATHS; then
            ntfy publish --quiet \
              --title "cachix push failed on ${config.networking.hostName}" \
              "$OUT_PATHS"
          fi
        '';
      };
    in
    {
      age.secrets.cachix-token.file = ../secrets/cachix-token.age;

      nix.settings.post-build-hook = lib.getExe pushHook;
    };
}
