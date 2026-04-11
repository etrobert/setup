{
  lib,
  symlinkJoin,
  makeWrapper,
  zsh,
  writeText,
  linkFarm,
  zsh-autosuggestions,
  zsh-syntax-highlighting,
}:
let
  zshrcFinal = writeText "zshrc" ''
    source ${./config/.zshrc}
    source ${./alias.sh}
    source ${zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh
    source ${zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
  '';

  zprofile = writeText "zprofile" /* bash */ ''
    emulate sh
    . ~/.profile
    emulate zsh
  '';

  zdotdir = linkFarm "zdotdir" [
    {
      name = ".zshrc";
      path = zshrcFinal;
    }
    {
      name = ".zprofile";
      path = zprofile;
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
