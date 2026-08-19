{ fzf, wrapPackage }:
# Scroll the preview with ctrl-u/ctrl-d (nvim-style half pages) in every fzf.
# Prepended, so an FZF_DEFAULT_OPTS set at runtime can still override it.
wrapPackage {
  package = fzf;
  inheritPath = true;

  run = [
    ''export FZF_DEFAULT_OPTS="--bind ctrl-u:preview-half-page-up,ctrl-d:preview-half-page-down''${FZF_DEFAULT_OPTS:+ $FZF_DEFAULT_OPTS}"''
  ];
}
