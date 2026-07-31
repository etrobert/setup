_: {
  flake.nixosModules.navidrome =
    { lib, ... }:
    {
      services.navidrome = {
        enable = true;
        settings = {
          Address = "0.0.0.0";
          MusicFolder = "/home/soft/sync/music";
          DataFolder = "/home/soft/.local/share/navidrome";
        };
        user = "soft";
      };

      # MusicFolder and DataFolder both live under /home, which the upstream
      # unit makes inaccessible.
      systemd.services.navidrome.serviceConfig.ProtectHome = lib.mkForce "read-only";
    };
}
