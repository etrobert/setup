{
  lib,
  inputs',
  wrapPackage,
  zsh,
  writeText,
  linkFarm,
  zsh-autosuggestions,
  zsh-syntax-highlighting,
  fzf,
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
in
wrapPackage {
  package = zsh;
  # makeBinaryWrapper is required: it supports --inherit-argv0, which the
  # shell-script makeWrapper does not.
  binaryWrapper = true;
  # --inherit-argv0 preserves the login-shell dash in argv[0] (e.g. `-zsh`)
  # so zsh is correctly detected as a login shell.  A makeWrapper shell-script
  # wrapper loses it to the shebang re-exec, demoting login shells to
  # non-login.  See issue #225.
  inheritArgv0 = true;
  # zsh is an interactive shell: it must inherit PATH from the environment so
  # user commands resolve normally.  inheritPath = true with no runtimeInputs
  # causes wrapPackage to omit the PATH line entirely, which avoids the bare ':'
  # that makeBinaryWrapper's C prefix function would prepend with an empty value.
  inheritPath = true;
  env = {
    ZDOTDIR = zdotdir;
  };
  passthru = {
    shellPath = "/bin/zsh";
  };
  checks = [
    "${zsh}/bin/zsh -n ${./zshrc}"
    "${zsh}/bin/zsh -n ${./alias.sh}"
  ];
}
