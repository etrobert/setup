{
  lib,
  inputs',
  wrapPackage,
  zsh,
  writeText,
  linkFarm,
  zsh-autosuggestions,
  zsh-syntax-highlighting,
  fzf-wrapped,
  zoxide,
  atuin-wrapped,
}:
let
  pronto = lib.getExe inputs'.pronto.packages.default;

  zshrcFinal = writeText "zshrc" /* zsh */ ''
    source ${./zshrc}

    setopt PROMPT_SUBST
    # Must live inside PS1: drawing the prompt resets the tmux line flags, so a
    # mark emitted before it is wiped.
    _prompt_mark=$'\e]133;A\a'
    PS1="%{$_prompt_mark%}"'$(${pronto} $? --zsh)'
    RPROMPT='$(${pronto} $? --rprompt --zsh)'

    source ${./alias.sh}
    if [[ $options[zle] = on ]]; then
      # atuin owns ^R; empty keeps fzf's ^T, alt-c and tab completion.
      FZF_CTRL_R_COMMAND=""
      source <(${fzf-wrapped}/bin/fzf --zsh)
      source <(${atuin-wrapped}/bin/atuin init zsh)
    fi
    source <(${zoxide}/bin/zoxide init zsh)
    source ${zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh
    source ${zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
  '';

  zdotdir = linkFarm "zdotdir" [
    {
      name = ".zshrc";
      path = zshrcFinal;
    }
    {
      # Sourced by every zsh, even non-interactive ones — unlike .zshrc.
      name = ".zshenv";
      path = ./zshenv;
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
