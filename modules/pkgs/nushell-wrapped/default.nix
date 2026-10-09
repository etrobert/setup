_: {
  perSystem =
    { pkgs, self', ... }:
    {
      packages.nushell-wrapped = self'.legacyPackages.wrapPackage {
        package = pkgs.nushell;
        flags = [ "--config ${./config.nu}" ];
        inheritPath = true;
      };
    };
}
