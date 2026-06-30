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
    homeConfigurations = {
      "soft@tower" = withSystem "x86_64-linux" (
        { pkgs, ... }:
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ self.homeModules.linux ];
        }
      );

      "soft@leod" = withSystem "x86_64-linux" (
        { pkgs, ... }:
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ self.homeModules.linux ];
        }
      );

      "soft@aaron" = withSystem "aarch64-darwin" (
        { pkgs, ... }:
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ self.homeModules.darwin ];
        }
      );

    };
  };
}
