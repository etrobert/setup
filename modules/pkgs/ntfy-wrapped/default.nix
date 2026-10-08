_: {
  perSystem =
    { pkgs, self', ... }:
    {
      packages.ntfy-wrapped = self'.legacyPackages.wrapPackage {
        package = pkgs.ntfy-sh;
        setDefaults.NTFY_TOPIC = "http://tower:2586/home";
      };
    };
}
