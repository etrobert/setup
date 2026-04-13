{
  lib,
  inputs',
  symlinkJoin,
  makeWrapper,
  zsh,
  writeText,
  linkFarm,
  direnv,
  zsh-autosuggestions,
  zsh-syntax-highlighting,
  fzf,
  runCommandLocal,
}:
let
  pronto = lib.getExe inputs'.pronto.packages.default;

  zshrcFinal = writeText "zshrc" /* zsh */ ''
    source ${./zshrc}

    setopt PROMPT_SUBST
    PS1='$(${pronto} $? --zsh)'
    RPROMPT='$(${pronto} $? --rprompt --zsh)'

    eval "$(${lib.getExe direnv} hook zsh)"

    source ${./alias.sh}
    if [[ $options[zle] = on ]]; then
      source <(${fzf}/bin/fzf --zsh)
    fi
    source ${zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh
    source ${zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
  '';

  zprofile = writeText "zprofile" /* zsh */ ''
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

  _checks = runCommandLocal "zsh-config-check" { } ''
    ${zsh}/bin/zsh -n ${./zshrc}
    ${zsh}/bin/zsh -n ${./alias.sh}
    mkdir $out
  '';
in
symlinkJoin {
  name = "zsh-wrapped";
  nativeBuildInputs = [ makeWrapper ];
  paths = [
    zsh
    _checks
  ];
  meta.mainProgram = "zsh";
  postBuild = ''
    wrapProgram $out/bin/zsh \
      --set ZDOTDIR ${zdotdir}
  '';
  passthru.shellPath = "/bin/zsh";
}
