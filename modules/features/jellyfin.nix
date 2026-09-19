_: {
  flake.nixosModules.jellyfin = {
    services = {
      jellyfin.enable = true;

      # Jellyfin's own login is the gate; 8096 itself is opened nowhere.
      caddy.virtualHosts."watch.etiennerobert.com".extraConfig = /* caddy */ ''
        reverse_proxy localhost:8096
      '';
    };
  };
}
