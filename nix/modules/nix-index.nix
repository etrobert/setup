{ inputs, ... }:
{
  flake.nixosModules.nixIndex =
    { config, ... }:
    {
      imports = [ inputs.nix-index-database.nixosModules.default ];

      programs = {
        nix-index-database.comma.enable = true;

        # Disable command-not-found handler (too slow).
        # Package is added manually so nix-locate stays in PATH.
        nix-index.enable = false;
      };

      environment.systemPackages = [ config.programs.nix-index.package ];
    };
}
