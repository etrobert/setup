# Wraps the llm CLI (simonw/llm) so switching between model providers needs
# no imperative setup (`llm keys set`, hand-edited config in $HOME):
#  - OpenAI: OPENAI_API_KEY read at runtime from the agenix secret (an
#    existing value in the environment wins), mirroring hass-cli-wrapped
#  - GitHub Copilot: extra-openai-models.yaml routes copilot-* models through
#    the local copilot-api proxy (modules/copilot-api.nix, port 4141)
#  - Ollama: llm-ollama plugin baked in; talks to a server on localhost:11434
#
# llm reads extra-openai-models.yaml from LLM_USER_PATH, but that directory
# must stay writable (llm keeps logs.db there), so it can't point at the
# store. The wrapper points it at a state directory and refreshes the
# store-sourced config there on every launch, keeping the file declarative.
{
  llm,
  writeText,
  wrapPackage,
}:
let
  extraOpenaiModels = writeText "extra-openai-models.yaml" ''
    - model_id: copilot-gpt-4.1
      model_name: gpt-4.1
      api_base: http://localhost:4141/v1
    - model_id: copilot-sonnet
      model_name: claude-sonnet-4.6
      api_base: http://localhost:4141/v1
  '';
in
wrapPackage {
  package = llm.withPlugins { llm-ollama = true; };

  run = [
    ''export LLM_USER_PATH="''${LLM_USER_PATH:-''${XDG_STATE_HOME:-$HOME/.local/state}/llm}"''
    ''mkdir -p "$LLM_USER_PATH"''
    ''cp -f ${extraOpenaiModels} "$LLM_USER_PATH/extra-openai-models.yaml"''
    ''export OPENAI_API_KEY="''${OPENAI_API_KEY:-$(< /run/agenix/openai-api-key)}"''
  ];
}
