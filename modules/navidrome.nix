_: {
  flake.nixosModules.navidrome =
    { lib, ... }:
    let
      user = "soft";
      home = "/home/${user}";
    in
    {
      services.navidrome = {
        enable = true;
        inherit user;

        settings = {
          # Upstream defaults to loopback. Navidrome is reached over Tailscale
          # as tower:4533; port 4533 is deliberately left out of the firewall,
          # so binding every interface does not expose it to the LAN.
          Address = "0.0.0.0";
          MusicFolder = "${home}/sync/music";
          DataFolder = "${home}/.local/share/navidrome";
        };
      };

      # The upstream unit builds its own filesystem root and binds MusicFolder
      # and DataFolder into it, but its ProtectHome=true would make /home
      # inaccessible and shadow both binds.
      systemd.services.navidrome.serviceConfig.ProtectHome = lib.mkForce "read-only";
    };
}
