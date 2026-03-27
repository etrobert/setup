{
  self,
  inputs,
  withSystem,
  ...
}:
let
  inherit (inputs) home-manager;
in
{
  flake = {
    homeConfigurations =
      let
        mkHome =
          { system, module }:
          withSystem system (
            { pkgs, ... }:
            home-manager.lib.homeManagerConfiguration {
              inherit pkgs;
              modules = [ module ];
            }
          );

        mkLinuxHome = mkHome {
          system = "x86_64-linux";
          module = self.homeModules.linux;
        };

        mkDarwinHome = mkHome {
          system = "aarch64-darwin";
          module = self.homeModules.darwin;
        };
      in
      {
        "soft@tower" = mkLinuxHome;
        "soft@leod" = mkLinuxHome;
        "soft@aaron" = mkDarwinHome;
      };
  };
}
