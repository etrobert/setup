{
  lib,
  symlinkJoin,
  makeWrapper,
  zsh,
  writeText,
  linkFarm,
  zsh-autosuggestions,
}:
let
  zshrcFinal = writeText "zshrc" ''
    source ${./config/.zshrc}
    source ${zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh
  '';
  zdotdir = linkFarm "zdotdir" [
    {
      name = ".zshrc";
      path = zshrcFinal;
    }
  ];
in
symlinkJoin {
  name = "zsh-wrapped";
  nativeBuildInputs = [ makeWrapper ];
  paths = [ zsh ];
  meta.mainProgram = "zsh";
  postBuild = ''
    wrapProgram $out/bin/zsh \
      --set ZDOTDIR ${zdotdir} \
      --prefix PATH : ${lib.makeBinPath [ ]}
  '';
}
