_: {
  perSystem =
    { pkgs, self', ... }:
    {
      packages.tmux-wrapped = self'.legacyPackages.wrapPackage {
        package = pkgs.tmux;
        flags = [ "-f ${./tmux.conf}" ];
        inheritPath = true;
      };
    };
}
