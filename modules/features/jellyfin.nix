_: {
  flake.nixosModules.jellyfin = _: {
    services = {
      jellyfin.enable = true;

      # Jellyfin's own login is the gate; 8096 itself is opened nowhere.
      caddy.virtualHosts."watch.etiennerobert.com".extraConfig = /* caddy */ ''
        reverse_proxy localhost:8096
      '';
    };

    # Libraries live under /tank/media; a scan before the mount marks them missing.
    systemd.services.jellyfin.unitConfig.RequiresMountsFor = [ "/tank/media" ];
  };
}
