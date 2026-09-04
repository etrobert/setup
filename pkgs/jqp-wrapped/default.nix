_: {
  perSystem =
    {
      config,
      pkgs,
      ...
    }:
    {
      packages.jqp-wrapped = config.lib.wrapPackage {
        package = pkgs.jqp;

        # jqp copies the query/results by shelling out to wl-copy or pbcopy
        # (atotto/clipboard), so a cleared PATH would break ctrl-y.
        inheritPath = true;

        # Without it the dark-background default is chroma's `vim` style, whose
        # LiteralString is #cd0000 — every JSON string renders red.
        flags = [ "--theme catppuccin-macchiato" ];
      };
    };
}
