# Wraps the goose CLI so it drives tower's ollama out of the box: `goose` and
# `goose run -t "…"` reach the local models with no config.yaml to write first.
# goose reads these three from the environment before its config file, and
# --set-default leaves an existing value (or a `goose configure` run) in charge.
# Endpoint mirrors host/port in modules/features/ollama.nix; the model mirrors
# the one preloaded there.
{
  goose-cli,
  wrapPackage,
}:
wrapPackage {
  package = goose-cli;

  # goose executes shell commands on the user's behalf, so it needs the caller's
  # PATH rather than the empty one wrapPackage installs by default.
  inheritPath = true;

  setDefaults = {
    GOOSE_PROVIDER = "ollama";
    GOOSE_MODEL = "gpt-oss:20b";
    OLLAMA_HOST = "http://tower:11434";
  };
}
