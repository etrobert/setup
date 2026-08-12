{
  aichat-shim,
  aichat,
  coreutils,
  lib,
  wrapPackage,
}:
wrapPackage {
  package = aichat;
  # aichat runs the accepted command by spawning `$SHELL -c`, which needs PATH.
  inheritPath = true;
  runtimeInputs = [ coreutils ];

  # Start one shim per aichat process, in aichat's own directory, so claude
  # inherits it and reads that project's CLAUDE.md. The shim picks a free port
  # and writes the config naming it; `read` waits for that to be on disk.
  # $$ survives the exec below, so the shim can watch it to know when to stop.
  run = [
    ''
      _aichat_dir=$(mktemp --directory)
      exec 3< <(${lib.getExe aichat-shim} --parent $$ --config "$_aichat_dir/config.yaml")
      read -r _ <&3
      export AICHAT_CONFIG_FILE="$_aichat_dir/config.yaml"
    ''
  ];
}
