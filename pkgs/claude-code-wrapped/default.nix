{ inputs, ... }:
{
  perSystem =
    {
      pkgs,
      lib,
      self',
      inputs',
      ...
    }:
    let
      inherit (inputs) figma-mcp-plugin;

      # Latest Claude Code, ahead of nixpkgs' cadence (see flake.nix input).
      # Minimal variant: the full one bundles gh, which our wrapper does not
      # need (it manages PATH and ships its own gitconfig-bot).
      claude-code = inputs'.nix-claude-code.packages.claude-minimal;
    in
    {
      packages = rec {
        claude-code-wrapped = lib.makeOverridable (
          {
            extraEnv ? { },
            readTokenFromAgenix ? false,
            # Name of the installed binary. Variants override this (e.g.
            # "claude-copilot") so they can be installed alongside the base
            # "claude" without colliding.
            binName ? "claude",
          }:
          let
            statuslineScript = pkgs.callPackage ./claude-plan-usage.nix { };
            formatFileScript = pkgs.callPackage ./format-file.nix { };
            rateLimitNotifyScript = pkgs.callPackage ./claude-rate-limit-notify.nix {
              ntfy-sh = self'.packages.ntfy-wrapped;
            };
            sessionHostScript = pkgs.callPackage ./claude-session-host.nix { };

            runtimeInputs = [
              statuslineScript
              formatFileScript
              rateLimitNotifyScript
              sessionHostScript
              self'.packages.hass-cli-wrapped
              self'.packages.git-wrapped
            ]
            ++ (with pkgs; [
              coreutils
              nix
              # Voice input (hold space) records via SoX's `rec`. Its bundled native
              # audio-capture module needs libasound.so.2, which isn't in this closure,
              # so it falls back to `rec`/`arecord` on PATH — neither of which we'd
              # otherwise provide.
              sox
            ]);

            # `$(<file)` builtin so the read doesn't
            # need `cat` on the caller's PATH, and a bare assignment so `set -e` aborts on
            # an unreadable secret instead of baking in an empty token.
            agenixTokenRun = lib.optionals readTokenFromAgenix [
              ''ANTHROPIC_AUTH_TOKEN="$(< /run/agenix/z-ai-auth-token)"''
              "export ANTHROPIC_AUTH_TOKEN"
            ];
          in
          pkgs.wrapPackage {
            package = claude-code;
            # Variants (e.g. claude-glm, claude-copilot) get renamed before wrapping;
            # the default "claude" matches the package's mainProgram, so it's a no-op.
            inherit binName;
            env = {
              CLAUDE_CODE_NO_FLICKER = "1";
            }
            // extraEnv;
            inheritPath = true;
            # Read-only store path: Claude Code loads a --plugin-dir plugin without
            # writing to it, so no marketplace install (gitignored cache) is needed.
            flags = [
              "--plugin-dir ${figma-mcp-plugin}"
              # Remote MCP servers, carried as plugins rather than --mcp-config, whose
              # variadic argument would swallow the user's own arguments when the
              # wrapper prepends it.
              "--plugin-dir ${./railway-mcp-plugin}"
              "--plugin-dir ${./linear-mcp-plugin}"
            ];
            run = [
              # Mutable path, not a store copy: Claude writes runtime state (sessions,
              # credentials, project data) into CLAUDE_CONFIG_DIR, so it can't be read-only.
              # An ambient value wins, so CI can point at its own checkout of this config.
              ''export CLAUDE_CONFIG_DIR="''${CLAUDE_CONFIG_DIR:-$HOME/work/setup/main/pkgs/claude-code-wrapped/config}"''
            ]
            ++ agenixTokenRun;
            inherit runtimeInputs;
          }
        ) { };

        claude-code-wrapped-glm = claude-code-wrapped.override {
          extraEnv = {
            ANTHROPIC_BASE_URL = "https://api.z.ai/api/anthropic";
            API_TIMEOUT_MS = "3000000";
            ANTHROPIC_DEFAULT_HAIKU_MODEL = "glm-4.5-air";
            ANTHROPIC_DEFAULT_SONNET_MODEL = "glm-5.1";
            ANTHROPIC_DEFAULT_OPUS_MODEL = "glm-5.1";
          };
          readTokenFromAgenix = true;
          binName = "claude-glm";
        };

        claude-code-wrapped-copilot = claude-code-wrapped.override {
          extraEnv = {
            ANTHROPIC_BASE_URL = "http://localhost:4141";
            ANTHROPIC_AUTH_TOKEN = "dummy"; # proxy authenticates via GitHub itself
            API_TIMEOUT_MS = "3000000";
            ANTHROPIC_DEFAULT_HAIKU_MODEL = "claude-haiku-4.5";
            ANTHROPIC_DEFAULT_SONNET_MODEL = "claude-sonnet-4.6";
            # Opus is unavailable on Copilot Pro; degrade to Sonnet rather than error.
            ANTHROPIC_DEFAULT_OPUS_MODEL = "claude-sonnet-4.6";
          };
          binName = "claude-copilot";
        };
      };
    };
}
