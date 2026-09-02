_: {
  perSystem =
    {
      config,
      pkgs,
      ...
    }:
    {
      packages.fzf-wrapped = config.lib.wrapPackage {
        package = pkgs.fzf;

        # fzf runs preview/execute commands via $SHELL from the caller's PATH.
        inheritPath = true;

        # A flag, not env: fzf's own widgets pass their whole option set through
        # FZF_DEFAULT_OPTS, which --set would discard (ctrl-r would lose --read0).
        flags = [ "--bind ctrl-u:preview-half-page-up,ctrl-d:preview-half-page-down" ];
      };
    };
}
