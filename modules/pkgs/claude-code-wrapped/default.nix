{ self, ... }:
{
  perSystem =
    {
      pkgs,
      self',
      inputs',
      ...
    }:
    let
      # Latest Claude Code, ahead of nixpkgs' cadence (see flake.nix input).
      # Minimal variant: the full one bundles gh, which our wrapper does not
      # need (it manages PATH and ships its own gitconfig-bot).
      claude-code = inputs'.nix-claude-code.packages.claude-minimal;

      makeClaudeCode =
        {
          extraEnv ? { },
          # Name of the installed binary. Variants override this (e.g.
          # "claude-copilot") so they can be installed alongside the base
          # "claude" without colliding.
          binName ? "claude",
        }:
        let
          statuslineScript = pkgs.callPackage ./_scripts/claude-plan-usage.nix { };
          formatFileScript = pkgs.callPackage ./_scripts/format-file.nix { };
          rateLimitNotifyScript = pkgs.callPackage ./_scripts/claude-rate-limit-notify.nix {
            ntfy-sh = self'.packages.ntfy-wrapped;
          };
          sessionHostScript = pkgs.callPackage ./_scripts/claude-session-host.nix { };

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
        in
        self.lib.wrapPackage pkgs {
          package = claude-code;
          # Variants (e.g. claude-copilot) get renamed before wrapping;
          # the default "claude" matches the package's mainProgram, so it's a no-op.
          inherit binName;
          env = {
            CLAUDE_CODE_NO_FLICKER = "1";
            # Env rather than settings.json: covers dispatch's own CLAUDE_CONFIG_DIR.
            CLAUDE_CODE_DISABLE_AUTO_MEMORY = "1";
          }
          // extraEnv;
          inheritPath = true;
          # Read-only store path: Claude Code loads a --plugin-dir plugin without
          # writing to it, so no marketplace install (gitignored cache) is needed.
          flags = [
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
            ''export CLAUDE_CONFIG_DIR="''${CLAUDE_CONFIG_DIR:-$HOME/work/setup/main/modules/pkgs/claude-code-wrapped/config}"''
          ];
          inherit runtimeInputs;
        };
    in
    {
      packages = {
        claude-code-wrapped = makeClaudeCode { };

        claude-code-wrapped-copilot = makeClaudeCode {
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
