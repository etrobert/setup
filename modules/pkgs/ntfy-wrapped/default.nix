{ self, ... }:
let
  inherit (self.nixosConfigurations.tower.config.services.ntfy-sh.settings) base-url;
in
{
  perSystem =
    { pkgs, self', ... }:
    {
      packages.ntfy-wrapped = self'.legacyPackages.wrapPackage {
        package = pkgs.ntfy-sh;
        # --set-default, so an NTFY_TOPIC in the environment still wins for ad-hoc
        # overrides.
        setDefaults.NTFY_TOPIC = "${base-url}/home";
      };
    };
}
