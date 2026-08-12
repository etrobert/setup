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
  backend = writeShellApplication {
    name = "aichat-claude-backend";
    runtimeInputs = [ gnused ];
    text = ''
      ${lib.getExe claude-code-wrapped} "$@" | sed '/^```/d'
    '';
  };

  config =
    writeText "aichat-claude.yaml" # yaml
      ''
        ---
        model: claude:haiku
        clients:
          - type: command
            name: claude
            command: ${lib.getExe backend}
            args:
              - --print
              - --model
              - "{model}"
              - --strict-mcp-config
              - --append-system-prompt
              - "{system}"
              # Otherwise claude answers agentically: asked to search for TODO it
              # runs the search rather than handing back the command.
              - --disallowed-tools
              - Bash,Read,Write,Edit,Glob,Grep,Task,WebFetch,WebSearch,NotebookEdit
            models:
              - name: haiku
      '';
in
wrapPackage {
  package = aichat;
  binName = "aichat-claude";
  # aichat runs the accepted command by spawning `$SHELL -c`, which needs PATH.
  inheritPath = true;
  setDefaults.AICHAT_CONFIG_FILE = "${config}";
  checks = [
    "AICHAT_CONFIG_FILE=${config} HOME=$(mktemp -d) ${aichat}/bin/aichat --dry-run -e 'list files' >/dev/null"
  ];
}
