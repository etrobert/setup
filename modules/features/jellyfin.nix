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
          guid = "f69e946a-4b3c-4e9a-8f0a-8d7c1b2c4d9b";
          version = "12.11.0.0";
          targetAbi = "12.0.0.0";
          url = "https://github.com/n00bcodr/Jellyfin-Enhanced/releases/download/12.11.0.0/Jellyfin.Plugin.JellyfinEnhanced_12.0.0.zip";
          hash = "sha256-9s0EscClhWTOAOVnOzzSLNagxWVi9BF2chXEgqtiz7Q=";
        }
        {
          name = "Home Screen Sections";
          guid = "b8298e01-2697-407a-b44d-aa8dc795e850";
          version = "3.0.2.0";
          targetAbi = "12.1.0.0";
          url = "https://github.com/IAmParadox27/jellyfin-plugin-home-sections/releases/download/3.0.2.0/Release-12.1.0.zip";
          hash = "sha256-juoZ+0KcyylmXGwrjmHylF9eDX9xhviLjRIrPEjUMT0=";
        }
        # File Transformation and Plugin Pages: required by Home Screen Sections.
        {
          name = "File Transformation";
          guid = "5e87cc92-571a-4d8d-8d98-d2d4147f9f90";
          version = "3.0.1.0";
          targetAbi = "12.1.0.0";
          url = "https://github.com/IAmParadox27/jellyfin-plugin-file-transformation/releases/download/3.0.1.0/Release-12.1.0.zip";
          hash = "sha256-sYZMJERlI3vAKdYErT0foZoE+zbTJ2iB+5JPJ3ZogUo=";
        }
        {
          name = "Plugin Pages";
          guid = "5b6550fa-a014-4f4c-8a2c-59a43680ac6d";
          version = "3.0.1.0";
          targetAbi = "12.1.0.0";
          url = "https://github.com/IAmParadox27/jellyfin-plugin-pages/releases/download/3.0.1.0/Release-12.1.0.zip";
          hash = "sha256-YLivNVavLVm+XqY03DX2CdRibMsCoL2kzVSJccPj8X4=";
        }
        {
          name = "Intro Skipper";
          guid = "c83d86bb-a1e0-4c35-a113-e2101cf4ee6b";
          version = "12.0.4.0";
          targetAbi = "12.0.0.0";
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
      # The release zips carry no meta.json; without one Jellyfin invents a plugin id.
      writePlugin =
        {
          name,
          guid,
          version,
          targetAbi,
          url,
          hash,
        }:
        let
          dir = "${config.services.jellyfin.dataDir}/plugins/${name}_${version}";
          files = pkgs.fetchzip {
            inherit url hash;
            stripRoot = false;
          };
          meta = builtins.toFile "meta.json" (
            builtins.toJSON {
              inherit
                name
                guid
                version
                targetAbi
                ;
            }
          );
        in
        /* bash */ ''
          rm --recursive --force '${dir}'
          cp --recursive --no-preserve=mode '${files}' '${dir}'
          cp --no-preserve=mode '${meta}' '${dir}/meta.json'
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

      systemd.services.jellyfin = {
        # Libraries live under /tank/media; a scan before the mount marks them missing.
        unitConfig.RequiresMountsFor = [ "/tank/media" ];

        serviceConfig.LoadCredential = [ "api-key:${config.age.secrets.jellyfin-api-key.path}" ];

        path = [ pkgs.sqlite ];

        # preStart, not tmpfiles: Jellyfin caches options.xml, so a change must restart it.
        # The API key goes straight into the database: Jellyfin's API mints one only for an admin login.
        preStart = lib.concatLines (
          lib.mapAttrsToList writeLibrary libraries
          ++ map writePlugin plugins
          ++ [
            /* bash */ ''
              sqlite3 '${config.services.jellyfin.dataDir}/data/jellyfin.db' \
                "DELETE FROM ApiKeys WHERE Name = 'NixOS';
                 INSERT INTO ApiKeys (DateCreated, DateLastActivity, Name, AccessToken)
                 VALUES (datetime('now'), datetime('now'), 'NixOS', '$(cat "$CREDENTIALS_DIRECTORY/api-key")');"
            ''
          ]
        );
      };
    };
}
