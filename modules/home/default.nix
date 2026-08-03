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
