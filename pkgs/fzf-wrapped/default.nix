{ fzf, wrapPackage }:
wrapPackage {
  package = fzf;

  # fzf runs preview/execute commands via $SHELL from the caller's PATH.
  inheritPath = true;

  run = [
    ''export FZF_DEFAULT_OPTS="--bind ctrl-u:preview-half-page-up,ctrl-d:preview-half-page-down''${FZF_DEFAULT_OPTS:+ $FZF_DEFAULT_OPTS}"''
  ];
}
