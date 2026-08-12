{
  aichat,
  claude-code-wrapped,
  lib,
  wrapPackage,
  writeText,
}:
let
  # Both backends in one config: `??` takes the default, `???` asks for claude
  # with -m.
  config = writeText "aichat.yaml" (
    builtins.replaceStrings [ "@claude@" ] [ (lib.getExe claude-code-wrapped) ] (
      builtins.readFile ./config.yaml
    )
  );
in
wrapPackage {
  package = aichat;
  # aichat runs the accepted command by spawning `$SHELL -c`, which needs PATH.
  inheritPath = true;
  setDefaults.AICHAT_CONFIG_FILE = "${config}";
  # --dry-run fails the build on wrong config
  checks = [
    "AICHAT_CONFIG_FILE=${config} HOME=$(mktemp -d) ${aichat}/bin/aichat --dry-run -e 'list files' >/dev/null"
  ];
}
