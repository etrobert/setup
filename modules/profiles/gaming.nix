{ self, ... }:
{
  flake.nixosModules.gaming =
    { pkgs, ... }:
    {
      imports = [ self.nixosModules.ankama-launcher ];

      programs.steam.enable = true;

      environment.systemPackages = [ pkgs.heroic ];

      allowedUnfreePackages = [
        "steam"
        "steam-unwrapped"
      ];
    };
}
