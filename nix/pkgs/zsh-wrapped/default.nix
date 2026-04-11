{
  lib,
  symlinkJoin,
  makeWrapper,
  zsh,
  writeTextDir,
}:
let
  config = writeTextDir "zsh/.zshrc" /* zsh */ ''
    PS1='$(pronto $? --zsh)'
  '';
in
symlinkJoin {
  name = "zsh-wrapped";
  nativeBuildInputs = [ makeWrapper ];
  paths = [ zsh ];
  meta.mainProgram = "zsh";
  postBuild = ''
    wrapProgram $out/bin/zsh \
      --set ZDOTDIR ${config} \
      --prefix PATH : ${lib.makeBinPath [ ]}
  '';
}
