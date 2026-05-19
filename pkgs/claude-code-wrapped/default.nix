{
  symlinkJoin,
  makeWrapper,
  claude-code,
}:
symlinkJoin {
  name = "claude-code-wrapped";
  nativeBuildInputs = [ makeWrapper ];
  paths = [ claude-code ];
  meta.mainProgram = "claude";
  postBuild = ''
    wrapProgram $out/bin/claude \
      --set CLAUDE_CODE_NO_FLICKER 1
  '';
}
