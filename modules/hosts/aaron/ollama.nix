# Ollama on aaron (macOS).
#
# nix-darwin has no services.ollama, and the homebrew ollama formula is broken
# for inference on macOS ARM since 0.30.x (ships no llama-server; see
# Homebrew/homebrew-core#285917). The cask works but is a GUI app. So run the
# nixpkgs build (complete, with its own runner + embedded Metal) as a launchd
# user agent, plus a one-shot agent that pulls the declared models.
#
# This whole module is a temporary shim: when nix-darwin gains a native
# services.ollama (https://github.com/LnL7/nix-darwin/pull/972) the guard below
# fails the build, prompting migration to `services.ollama.enable` + loadModels.
{
  pkgs,
  lib,
  options,
  ...
}:
let
  # Models to ensure are present, pulled declaratively by the load-models agent.
  ollamaModels = [ "qwen3:8b" ];

  # Wait for the ollama server, then pull each model via the HTTP API.
  # /api/pull is a no-op for models already present, so this is safe to re-run.
  ollamaLoadModels = pkgs.writeShellApplication {
    name = "ollama-load-models";
    runtimeInputs = [
      pkgs.curl
      pkgs.coreutils
    ];
    inheritPath = false;
    # SC2043: the loop runs once today (single model) but generalises to many.
    excludeShellChecks = [ "SC2043" ];
    text = ''
      host="http://localhost:11434"
      for _ in $(seq 1 60); do
        curl --silent --fail "$host/api/tags" >/dev/null 2>&1 && break
        sleep 1
      done
      for model in ${lib.escapeShellArgs ollamaModels}; do
        echo "Ensuring model: $model"
        curl --silent --fail "$host/api/pull" \
          --data "{\"model\": \"$model\", \"stream\": false}" >/dev/null
      done
    '';
  };
in
{
  # Self-cleaning guard: fails the build once nix-darwin provides services.ollama
  # (#972), so we migrate to it rather than maintaining this shim forever.
  #
  # We deliberately do NOT guard on the homebrew formula fix
  # (Homebrew/homebrew-core#285917): migrating to brew once it ships llama-server
  # again is plausible, but Nix evaluation is pure and offline, so it cannot
  # inspect a homebrew bottle's contents or an issue's status — that condition is
  # not expressible as a Nix check. The native module is the better target anyway.
  assertions = [
    {
      assertion = !(options.services ? ollama);
      message = ''
        nix-darwin now provides services.ollama. Replace aaron's hand-rolled
        ollama launchd agents (serve + load-models) with the native module and
        delete this module.
      '';
    }
  ];

  # Run as a *user* agent, not a system daemon: launchd does not set $HOME for
  # it, so set it explicitly or ollama panics with "$HOME is not defined" when
  # locating ~/.ollama.
  launchd.user.agents.ollama =
    { config, ... }:
    {
      serviceConfig = {
        ProgramArguments = [
          "${lib.getExe pkgs.ollama}"
          "serve"
        ];
        RunAtLoad = true;
        KeepAlive = true;
        # /tmp/org.nixos.ollama.log
        StandardOutPath = "/tmp/${config.serviceConfig.Label}.log";
        StandardErrorPath = "/tmp/${config.serviceConfig.Label}.log";
      };
    };

  # One-shot user agent: pull the declared models once the serve agent is up.
  # Idempotent (/api/pull is a no-op for present models), so it is safe to
  # re-run on every login.
  launchd.user.agents.ollama-load-models = {
    serviceConfig = {
      ProgramArguments = [ "${lib.getExe ollamaLoadModels}" ];
      RunAtLoad = true;
      StandardOutPath = "/tmp/ollama-load-models.log";
      StandardErrorPath = "/tmp/ollama-load-models.log";
    };
  };
}
