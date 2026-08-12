{
  aichat,
  wrapPackage,
}:
wrapPackage {
  package = aichat;
  # aichat runs the accepted command by spawning `$SHELL -c`, which needs PATH.
  inheritPath = true;
  setDefaults.AICHAT_CONFIG_FILE = "${./config.yaml}";
  # --dry-run loads the config without sending a request, so a config that cannot
  # resolve its model fails the build rather than the next prompt.
  checks = [
    "AICHAT_CONFIG_FILE=${./config.yaml} HOME=$(mktemp -d) ${aichat}/bin/aichat --dry-run -e 'list files' >/dev/null"
  ];
}
