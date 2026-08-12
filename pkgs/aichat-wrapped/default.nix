{
  aichat,
  claude-code-wrapped,
  gnused,
  lib,
  wrapPackage,
  writeShellApplication,
  writeText,
}:
let
  # aichat runs whatever the client prints, and claude fences its answer in
  # markdown about one time in four however the prompt asks it not to.
  claude-backend = writeShellApplication {
    name = "aichat-claude-backend";
    runtimeInputs = [ gnused ];
    text = ''
      ${lib.getExe claude-code-wrapped} "$@" | sed '/^```/d'
    '';
  };

  # Both backends in one config: `??` takes the default, `???` asks for claude
  # with -m.
  config = writeText "aichat.yaml" (
    builtins.replaceStrings [ "@claude-backend@" ] [ (lib.getExe claude-backend) ] (
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
