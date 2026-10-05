_: {
  flake.nixosModules.jellyfin =
    {
      config,
      lib,
      pkgs,
      ...
    }:
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

      # Versions built for the installed Jellyfin, from each author's plugin repository manifest.
      plugins = [
        {
          name = "Jellyfin Enhanced";
          version = "12.11.0.0";
          url = "https://github.com/n00bcodr/Jellyfin-Enhanced/releases/download/12.11.0.0/Jellyfin.Plugin.JellyfinEnhanced_12.0.0.zip";
          hash = "sha256-9s0EscClhWTOAOVnOzzSLNagxWVi9BF2chXEgqtiz7Q=";
        }
        {
          name = "Home Screen Sections";
          version = "3.0.2.0";
          url = "https://github.com/IAmParadox27/jellyfin-plugin-home-sections/releases/download/3.0.2.0/Release-12.1.0.zip";
          hash = "sha256-juoZ+0KcyylmXGwrjmHylF9eDX9xhviLjRIrPEjUMT0=";
        }
        # File Transformation and Plugin Pages: required by Home Screen Sections.
        {
          name = "File Transformation";
          version = "3.0.1.0";
          url = "https://github.com/IAmParadox27/jellyfin-plugin-file-transformation/releases/download/3.0.1.0/Release-12.1.0.zip";
          hash = "sha256-sYZMJERlI3vAKdYErT0foZoE+zbTJ2iB+5JPJ3ZogUo=";
        }
        {
          name = "Plugin Pages";
          version = "3.0.1.0";
          url = "https://github.com/IAmParadox27/jellyfin-plugin-pages/releases/download/3.0.1.0/Release-12.1.0.zip";
          hash = "sha256-YLivNVavLVm+XqY03DX2CdRibMsCoL2kzVSJccPj8X4=";
        }
        {
          name = "Intro Skipper";
          version = "12.0.4.0";
          url = "https://github.com/intro-skipper/intro-skipper/releases/download/12.0/v12.0.4.0/intro-skipper-v12.0.4.0.zip";
          hash = "sha256-sPEZXGB3s+YI1E9+qJ3EWdKFu2gdqK7LfNjV4QjMlnA=";
        }
      ];

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

      # A copy, not a link: Jellyfin writes the plugin's status into meta.json.
      writePlugin =
        {
          name,
          version,
          url,
          hash,
        }:
        let
          dir = "${config.services.jellyfin.dataDir}/plugins/${name}_${version}";
          files = pkgs.fetchzip {
            inherit url hash;
            stripRoot = false;
          };
        in
        /* bash */ ''
          rm --recursive --force '${dir}'
          cp --recursive --no-preserve=mode '${files}' '${dir}'
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

      age.secrets.jellyfin-api-key.file = ../../secrets/jellyfin-api-key.age;

      systemd.services = {
        jellyfin = {
          # Libraries live under /tank/media; a scan before the mount marks them missing.
          unitConfig.RequiresMountsFor = [ "/tank/media" ];

          # preStart, not tmpfiles: Jellyfin caches options.xml, so a change must restart it.
          # The wipe drops any library that is no longer declared.
          preStart = lib.concatLines (
            [ "rm --recursive --force '${config.services.jellyfin.dataDir}/root/default'" ]
            ++ lib.mapAttrsToList writeLibrary libraries
            ++ [ "mkdir --parents '${config.services.jellyfin.dataDir}/plugins'" ]
            ++ map writePlugin plugins
          );
        };

        # Jellyfin's API mints a key only for an admin login, so the key goes straight into its database.
        jellyfin-api-key = {
          after = [ "jellyfin.service" ];
          partOf = [ "jellyfin.service" ];
          wantedBy = [ "jellyfin.service" ];
          path = [ pkgs.sqlite ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            User = config.services.jellyfin.user;
            LoadCredential = [ "api-key:${config.age.secrets.jellyfin-api-key.path}" ];
            TimeoutStartSec = "5min";
          };
          # Jellyfin creates its database on first start, and reads keys from it on every request.
          script = /* bash */ ''
            db='${config.services.jellyfin.dataDir}/data/jellyfin.db'
            until sqlite3 -readonly "$db" 'SELECT 1 FROM ApiKeys' > /dev/null 2>&1; do
              sleep 1
            done
            sqlite3 -cmd '.timeout 10000' "$db" \
              "DELETE FROM ApiKeys WHERE Name = 'NixOS';
               INSERT INTO ApiKeys (DateCreated, DateLastActivity, Name, AccessToken)
               VALUES (datetime('now'), datetime('now'), 'NixOS', '$(cat "$CREDENTIALS_DIRECTORY/api-key")');"
          '';
        };
      };
    };
}
