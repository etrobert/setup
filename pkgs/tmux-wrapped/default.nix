{ self, ... }:
{
  perSystem =
    {
      pkgs,
      ...
    }:
    {
      packages.tmux-wrapped = self.lib.wrapPackage pkgs {
        package = pkgs.tmux;
        flags = [ "-f ${./tmux.conf}" ];
        inheritPath = true;
      };
    };
}
