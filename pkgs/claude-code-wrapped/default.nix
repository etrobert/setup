{ symlinkJoin, claude-code }:
symlinkJoin {
  name = "claude-code-wrapped";
  paths = [ claude-code ];
  meta.mainProgram = "claude";
}
