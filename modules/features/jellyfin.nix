_: {
  flake.nixosModules.jellyfin =
    { config, lib, ... }:
    let
      libraries = {
        Movies = {
          type = "movies";
          path = "/tank/media/movies";
        };
        Shows = {
          type = "tvshows";
          path = "/tank/media/tv";
        };
      };

      # Unset options keep Jellyfin's defaults, which fetch metadata and posters from TMDb.
      options = builtins.toFile "options.xml" /* xml */ ''
        <?xml version="1.0" encoding="utf-8"?>
        <LibraryOptions>
          <EnableRealtimeMonitor>true</EnableRealtimeMonitor>
        </LibraryOptions>
      '';

      # Jellyfin registers a new library only at its next library scan.
      writeLibrary =
        name:
        { type, path }:
        let
          dir = "${config.services.jellyfin.dataDir}/root/default/${name}";
        in
        /* bash */ ''
          mkdir --parents '${dir}'
          touch '${dir}/${type}.collection'
          printf '%s' '${path}' > '${dir}/${baseNameOf path}.mblink'
          cp --no-preserve=mode '${options}' '${dir}/options.xml'
        '';
    in
    {
      services = {
        jellyfin.enable = true;

        # Jellyfin's own login is the gate; 8096 itself is opened nowhere.
        caddy.virtualHosts."watch.etiennerobert.com".extraConfig = /* caddy */ ''
          reverse_proxy localhost:8096
        '';
      };

      systemd.services.jellyfin = {
        # Libraries live under /tank/media; a scan before the mount marks them missing.
        unitConfig.RequiresMountsFor = [ "/tank/media" ];

        # preStart, not tmpfiles: Jellyfin caches options.xml, so a change must restart it.
        preStart = lib.concatLines (lib.mapAttrsToList writeLibrary libraries);
      };
    };
}
