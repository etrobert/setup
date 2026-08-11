_: {
  flake.nixosModules.gaming =
    { pkgs, ... }:
    {
      programs.steam.enable = true;

      environment.systemPackages = [ pkgs.heroic ];

      allowedUnfreePackages = [
        "steam"
        "steam-unwrapped"
      ];
    };
}
