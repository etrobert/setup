{ inputs, ... }:
let
  inherit (inputs) home-manager;
in
{
  flake = {
    homeConfigurations =
      let
        mkHome =
          {
            system,
            module,
          }:
          home-manager.lib.homeManagerConfiguration {
            pkgs = inputs.nixpkgs.legacyPackages.${system};
            modules = [
              { home.username = "soft"; }
              module
            ];
          };

        mkLinuxHome = mkHome {
          system = "x86_64-linux";
          module = ./linux.nix;
        };

        mkDarwinHome = mkHome {
          system = "aarch64-darwin";
          module = ./darwin.nix;
        };
      in
      {
        "soft@tower" = mkLinuxHome;
        "soft@leod" = mkLinuxHome;
        "soft@aaron" = mkDarwinHome;
      };
  };
}
