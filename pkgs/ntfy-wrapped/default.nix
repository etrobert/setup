{ self, ... }:
{
  perSystem =
    {
      pkgs,
      ...
    }:
    {
      packages.ntfy-wrapped = self.lib.wrapPackage pkgs {
        package = pkgs.ntfy-sh;
        # --set-default, so an NTFY_TOPIC in the environment still wins for ad-hoc
        # overrides.
        setDefaults.NTFY_TOPIC = "http://tower:2586/home";
      };
    };
}
