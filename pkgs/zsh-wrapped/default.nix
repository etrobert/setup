{
  lib,
  inputs',
  symlinkJoin,
  makeBinaryWrapper,
  zsh,
  writeText,
  linkFarm,
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

    source ${./alias.sh}
    if [[ $options[zle] = on ]]; then
      source <(${fzf}/bin/fzf --zsh)
    fi
    source ${zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh
    source ${zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
  '';

  zdotdir = linkFarm "zdotdir" [
    {
      name = ".zshrc";
      path = zshrcFinal;
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
  nativeBuildInputs = [ makeBinaryWrapper ];
  paths = [
    zsh
    _checks
  ];
  meta.mainProgram = "zsh";
  postBuild = ''
    # --inherit-argv0 preserves the login-shell dash in argv[0] (e.g. `-zsh`)
    # so zsh is correctly detected as a login shell. A makeWrapper shell-script
    # wrapper loses it to the shebang re-exec, demoting login shells to
    # non-login. See issue #225.
    wrapProgram $out/bin/zsh \
      --inherit-argv0 \
      --set ZDOTDIR ${zdotdir}
  '';
  passthru.shellPath = "/bin/zsh";
}
