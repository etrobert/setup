{
  symlinkJoin,
  makeWrapper,
  vscode,
}:
let
  userDataDir = ../../../vscode/Library + "/Application Support/Code/User";
in
symlinkJoin {
  name = "vscode-wrapped";
  nativeBuildInputs = [ makeWrapper ];
  paths = [ vscode ];
  meta.mainProgram = "code";
  postBuild = ''
    wrapProgram $out/bin/code \
      --add-flags "--user-data-dir '${userDataDir}'"
  '';
}
