# Wraps the pi coding agent so `pi` drives tower's ollama out of the box.
# Endpoint mirrors host/port in modules/features/ollama.nix; the model mirrors
# the one preloaded there.
#
# No --add-flags here on purpose: pi dispatches subcommands from argv[1], so any
# baked-in global flag turns `pi list` / `pi install` / `pi config` into a prompt
# for the model. Everything is configured through the environment and pi's own
# auto-discovery instead.
{
  pi-coding-agent,
  wrapPackage,
  writeText,
  coreutils,
  lib,
}:
let
  # pi auto-discovers extensions from <agent-dir>/extensions, following symlinks,
  # so the provider definition itself stays in the store and read-only. The
  # alternative, models.json, would have to be copied into the user's config
  # directory and overwritten on every launch to track this file.
  ollamaExtension =
    writeText "pi-ollama.js" # javascript
      ''
        export default function (pi) {
          pi.registerProvider("ollama", {
            name: "Ollama (tower)",
            baseUrl: "http://tower:11434/v1",
            // Placeholder: ollama ignores it, but pi hides models that have no
            // credential from --list-models and /model.
            apiKey: "ollama",
            api: "openai-completions",
            models: [
              {
                id: "gpt-oss:20b",
                name: "gpt-oss 20b (local)",
                reasoning: false,
                input: ["text"],
                cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
                contextWindow: 32768,
                maxTokens: 8192,
                // ollama's OpenAI-compatible endpoint rejects the `developer` role
                // and reasoning_effort that pi sends for reasoning-capable models.
                compat: { supportsDeveloperRole: false, supportsReasoningEffort: false },
              },
            ],
          });
        }
      '';

  # Only the two defaults, so this file carries no store path and never goes
  # stale. It seeds a missing settings.json and is not written again, leaving
  # the file to the user (and to /settings) from then on.
  defaultSettings = writeText "pi-settings.json" (
    builtins.toJSON {
      defaultProvider = "ollama";
      defaultModel = "gpt-oss:20b";
    }
  );

  ln = lib.getExe' coreutils "ln";
  mkdir = lib.getExe' coreutils "mkdir";
  install = lib.getExe' coreutils "install";
in
wrapPackage {
  package = pi-coding-agent;

  # pi runs shell commands on the user's behalf, so it needs the caller's PATH
  # rather than the empty one wrapPackage installs by default.
  inheritPath = true;

  # Absolute coreutils paths throughout: this prelude runs before the wrapper has
  # prefixed PATH.
  run = [
    # pi keeps credentials, settings and sessions under ~/.pi by default. Point
    # it at the XDG directories instead so it adds no dotdir to the home root.
    ''export PI_CODING_AGENT_DIR="''${PI_CODING_AGENT_DIR:-''${XDG_CONFIG_HOME:-$HOME/.config}/pi/agent}"''
    ''export PI_CODING_AGENT_SESSION_DIR="''${PI_CODING_AGENT_SESSION_DIR:-''${XDG_STATE_HOME:-$HOME/.local/state}/pi/sessions}"''

    # Re-point the symlink on every launch so a rebuild takes effect, rather than
    # leaving a dangling path to a garbage-collected store entry.
    ''
      ${mkdir} -p "$PI_CODING_AGENT_DIR/extensions"
      ${ln} -sfn ${ollamaExtension} "$PI_CODING_AGENT_DIR/extensions/ollama.js"
      [ -e "$PI_CODING_AGENT_DIR/settings.json" ] \
        || ${install} -m 644 ${defaultSettings} "$PI_CODING_AGENT_DIR/settings.json"
    ''
  ];
}
