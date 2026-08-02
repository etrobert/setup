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

      inherit (self'.packages) git-wrapped ntfy-wrapped hass-cli-wrapped;
    in
    {
      packages = {
        claude-code-wrapped = pkgs.callPackage ../pkgs/claude-code-wrapped {
          inherit
            claude-code
            git-wrapped
            ntfy-wrapped
            hass-cli-wrapped
            ;
        };

        claude-code-wrapped-glm = pkgs.callPackage ../pkgs/claude-code-wrapped {
          inherit
            claude-code
            git-wrapped
            ntfy-wrapped
            hass-cli-wrapped
            ;
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

        claude-code-wrapped-copilot = pkgs.callPackage ../pkgs/claude-code-wrapped {
          inherit
            claude-code
            git-wrapped
            ntfy-wrapped
            hass-cli-wrapped
            ;
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

        # TTS backends for `speak` (stdin -> audio). Selected at runtime via
        # $SPEAK_TTS; each is runnable standalone, e.g. `echo hi | nix run .#tts-say`.
        tts-say = pkgs.callPackage ../pkgs/claude-code-wrapped/tts-say.nix { };
        tts-piper = pkgs.callPackage ../pkgs/claude-code-wrapped/tts-piper.nix { };
      };
    };
}
