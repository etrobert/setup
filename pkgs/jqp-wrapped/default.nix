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

        flags = [ "--theme catppuccin-macchiato" ];
      };
    };
}
