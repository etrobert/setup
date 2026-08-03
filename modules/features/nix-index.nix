{ inputs, ... }:
let
  commonConfig =
    { config, ... }:
    {
      programs = {
        nix-index-database.comma.enable = true;

        # Disable command-not-found handler (too slow).
        # Package is added manually so nix-locate stays in PATH.
        nix-index.enable = false;
      };

      environment.systemPackages = [ config.programs.nix-index.package ];
    };
in
{
  flake.nixosModules.nixIndex.imports = [
    inputs.nix-index-database.nixosModules.default
    commonConfig
  ];

  flake.darwinModules.nixIndex.imports = [
    inputs.nix-index-database.darwinModules.default
    commonConfig
  ];
}
