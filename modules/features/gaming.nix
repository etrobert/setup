_: {
  flake.nixosModules.gaming =
    { self, pkgs, ... }:
    {
      programs.steam.enable = true;

      environment.systemPackages = [
        pkgs.heroic
        self.packages.${pkgs.stdenv.hostPlatform.system}.ankama-launcher
      ];

      allowedUnfreePackages = [
        "steam"
        "steam-unwrapped"
      ];
    };
}
