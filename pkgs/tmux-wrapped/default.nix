_: {
  perSystem =
    {
      config,
      pkgs,
      ...
    }:
    {
      packages.tmux-wrapped = config.lib.wrapPackage {
        package = pkgs.tmux;
        flags = [ "-f ${./tmux.conf}" ];
        inheritPath = true;
      };
    };
}
