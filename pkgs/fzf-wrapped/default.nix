{ fzf, wrapPackage }:
wrapPackage {
  package = fzf;

  # fzf runs preview/execute commands via $SHELL (or sh) found on the caller's
  # PATH; clearing it (inheritPath = false) breaks every preview.
  inheritPath = true;

  run = [
    ''export FZF_DEFAULT_OPTS="--bind ctrl-u:preview-half-page-up,ctrl-d:preview-half-page-down''${FZF_DEFAULT_OPTS:+ $FZF_DEFAULT_OPTS}"''
  ];
}
