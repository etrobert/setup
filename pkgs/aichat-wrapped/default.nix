{
  aichat,
  wrapPackage,
}:
wrapPackage {
  package = aichat;
  # aichat runs the accepted command by spawning `$SHELL -c`, which needs PATH.
  inheritPath = true;
  setDefaults.AICHAT_CONFIG_FILE = "${./config.yaml}";
  # --dry-run fails the build on wrong config
  checks = [
    "AICHAT_CONFIG_FILE=${./config.yaml} HOME=$(mktemp -d) ${aichat}/bin/aichat --dry-run -e 'list files' >/dev/null"
  ];
}
