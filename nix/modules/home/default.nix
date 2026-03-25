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
            username,
          }:
          home-manager.lib.homeManagerConfiguration {
            pkgs = inputs.nixpkgs.legacyPackages.${system};
            modules = [
              { home.username = username; }
              module
            ];
          };

        mkLinuxHome = mkHome {
          system = "x86_64-linux";
          module = ./linux.nix;
          username = "soft";
        };

        mkDarwinHome = mkHome {
          system = "aarch64-darwin";
          module = ./darwin.nix;
          username = "soft";
        };
      in
      {
        "soft@tower" = mkLinuxHome;
        "soft@leod" = mkLinuxHome;
        "soft@aaron" = mkDarwinHome;
      };
  };
}
