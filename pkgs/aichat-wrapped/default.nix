# Wraps aichat with a bundled config so `aichat -e "<request>"` translates plain
# English into a shell command on any machine with no per-host setup.  The API
# key comes from OPENAI_API_KEY, which pkgs/zsh-wrapped/zshrc exports from
# agenix.
{
  aichat,
  wrapPackage,
}:
wrapPackage {
  package = aichat;
  # aichat runs the accepted command by spawning `$SHELL -c <command>`, so the
  # wrapper must not clear PATH — the spawned shell inherits it, and the whole
  # point is to run the user's own tools.
  inheritPath = true;
  # Point aichat at the bundled read-only config.  AICHAT_CONFIG_FILE only moves
  # the config file, so sessions, roles and history still land in the default
  # config dir under $HOME, which stays writable.
  # --set-default, so an ad-hoc AICHAT_CONFIG_FILE still wins.
  setDefaults.AICHAT_CONFIG_FILE = "${./config.yaml}";
  # Load the bundled config at build time: --dry-run assembles the request
  # without sending it, so malformed YAML, or a model whose provider is missing
  # from `clients`, fails the build instead of the next request at the prompt.
  # A well-formed but wrong model id still only surfaces at runtime — aichat
  # accepts any id under a declared provider.
  checks = [
    "AICHAT_CONFIG_FILE=${./config.yaml} HOME=$(mktemp -d) ${aichat}/bin/aichat --dry-run -e 'list files' >/dev/null"
  ];
}
