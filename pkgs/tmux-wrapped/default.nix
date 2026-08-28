_: {
  perSystem =
    { pkgs, ... }:
    {
      packages.tmux-wrapped = pkgs.wrapPackage {
        package = pkgs.tmux;
        flags = [ "-f ${./tmux.conf}" ];
        inheritPath = true;
      };
    };
}
