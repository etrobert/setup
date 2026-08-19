{ fzf, wrapPackage }:
# Scroll the preview with ctrl-u/ctrl-d (nvim-style half pages) in every fzf.
# Prepended, so an FZF_DEFAULT_OPTS set at runtime can still override it.
wrapPackage {
  package = fzf;

  # fzf runs preview/execute commands via $SHELL (or sh) found on the caller's
  # PATH; clearing it (inheritPath = false) breaks every preview.
  inheritPath = true;

  prefixSpace.FZF_DEFAULT_OPTS = "--bind ctrl-u:preview-half-page-up,ctrl-d:preview-half-page-down";
}
