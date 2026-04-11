{
  lib,
  symlinkJoin,
  makeWrapper,
  zsh,
}:
symlinkJoin {
  name = "zsh-wrapped";
  nativeBuildInputs = [ makeWrapper ];
  paths = [ zsh ];
  meta.mainProgram = "zsh";
  postBuild = ''
    wrapProgram $out/bin/zsh \
      --set ZDOTDIR ${./config} \
      --prefix PATH : ${lib.makeBinPath [ ]}
  '';
}
