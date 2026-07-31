_: {
  flake.nixosModules.navidrome =
    { lib, ... }:
    {
      services.navidrome = {
        enable = true;
        settings = {
          # Upstream defaults to loopback. Navidrome is reached over Tailscale
          # as tower:4533; 4533 is deliberately absent from the firewall, so
          # binding every interface does not expose it to the LAN.
          Address = "0.0.0.0";
          MusicFolder = "/home/soft/sync/music";
        };
      };

      # MusicFolder sits under /home, which upstream's ProtectHome=true makes
      # inaccessible — shadowing the read-only bind the unit sets up for it.
      # "tmpfs" is the value systemd.exec(5) documents as still letting
      # BindReadOnlyPaths show through, and it hides the rest of $HOME by
      # itself rather than leaning on RootDirectory to have emptied it.
      systemd.services.navidrome.serviceConfig.ProtectHome = lib.mkForce "tmpfs";
    };
}
