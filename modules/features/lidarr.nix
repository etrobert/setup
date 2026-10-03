_: {
  flake.nixosModules.lidarr =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      port = config.services.lidarr.settings.server.port;

      # What Lidarr keeps in its database (indexer, download client, path mapping,
      # root folder, naming) is declared here and pushed over its API on every start.
      lidarr-setup = pkgs.writeShellApplication {
        name = "lidarr-setup";

        runtimeInputs = with pkgs; [
          coreutils
          curl
          jq
        ];

        inheritPath = false;

        text = /* bash */ ''
          base=http://127.0.0.1:${toString port}

          # Type=simple: lidarr.service counts as started before Lidarr listens.
          key=$(curl --silent --fail --retry 60 --retry-delay 2 --retry-connrefused --retry-all-errors \
            "$base/initialize.json" | jq --raw-output .apiKey)

          api() {
            local path=$1
            shift
            curl --silent --fail-with-body --header "X-Api-Key: $key" \
              --header 'Content-Type: application/json' "$@" "$base/api/v1/$path"
          }

          # Create the resource, or replace the one that shares its name.
          provider() {
            local path=$1 body=$2 id
            if id=$(api "$path" | jq --exit-status --argjson body "$body" '.[] | select(.name == $body.name).id'); then
              api "$path/$id" --request PUT --data "$(jq --argjson id "$id" '.id = $id' <<< "$body")"
            else
              api "$path" --data "$body"
            fi > /dev/null
          }

          # Create the resource unless one with the same key field exists.
          ensure() {
            local path=$1 field=$2 body=$3
            api "$path" | jq --exit-status --arg field "$field" --argjson body "$body" \
              'any(.[]; .[$field] == $body[$field])' > /dev/null ||
              api "$path" --data "$body" > /dev/null
          }

          # The default profiles are created after the server starts listening.
          until lossless=$(api qualityprofile | jq --exit-status '.[] | select(.name == "Lossless").id'); do
            sleep 1
          done
          standard=$(api metadataprofile | jq --exit-status '.[] | select(.name == "Standard").id')

          # Off, Lidarr drops imports flat into the artist folder under their original names.
          api config/naming | jq '
            .renameTracks = true
            | .standardTrackFormat = "{Album Title}{ (Album Disambiguation)}/{track:00} {Track Title}"
            | .multiDiscTrackFormat = "{Album Title}{ (Album Disambiguation)}/{medium:00}-{track:00} {Track Title}"
          ' | api config/naming --request PUT --data @- > /dev/null

          # charon's reaper is the only remover (transmission.nix); a client Lidarr may
          # not remove from is also what makes it hardlink instead of move.
          provider downloadclient "$(jq --null-input '{
            name: "torrents",
            implementation: "Transmission",
            configContract: "TransmissionSettings",
            enable: true,
            priority: 1,
            removeCompletedDownloads: false,
            tags: [],
            fields: [
              { name: "host", value: "torrents" },
              { name: "port", value: 80 }
            ]
          }')"

          ensure remotepathmapping host "$(jq --null-input '{
            host: "torrents",
            remotePath: "/var/lib/transmission/Downloads/",
            localPath: "/tank/media/torrents/"
          }')"

          # Transmission creates the category folder on charon at the first grab; the
          # health check wants its pulled copy to exist before that.
          mkdir --parents /tank/media/torrents/lidarr

          provider indexer "$(jq --null-input --arg key "$(< ${config.age.secrets.c411-api-key.path})" '{
            name: "c411",
            implementation: "Torznab",
            configContract: "TorznabSettings",
            enableRss: true,
            enableAutomaticSearch: true,
            enableInteractiveSearch: true,
            priority: 25,
            tags: [],
            fields: [
              { name: "baseUrl", value: "https://c411.org" },
              { name: "apiPath", value: "/api/torznab" },
              { name: "apiKey", value: $key },
              { name: "categories", value: [3010] }
            ]
          }')"

          # Saving scans the tree and adds every artist on it; monitored, they would all be hunted.
          ensure rootfolder path "$(jq --null-input --argjson quality "$lossless" --argjson metadata "$standard" '{
            name: "torrents",
            path: "/tank/media/music/torrents",
            defaultQualityProfileId: $quality,
            defaultMetadataProfileId: $metadata,
            defaultMonitorOption: "none",
            defaultNewItemMonitorOption: "none",
            defaultTags: []
          }')"
        '';
      };
    in
    {
      services = {
        lidarr = {
          enable = true;

          # soft:users owns the library and the landing zone; imports write into both.
          user = "soft";
          group = "users";

          settings = {
            # Lidarr defaults to *; only tsnsrv on loopback should reach it.
            server.bindaddress = "127.0.0.1";

            # No login: the tailnet is the only access control.
            # Not the default None: the UI then locks itself behind a setup modal that refuses None.
            # Capitalised: Lidarr parses the value as a C# enum, case-sensitively.
            auth.method = "External";
          };
        };

        tsnsrv.services.lidarr.toURL = "http://127.0.0.1:${toString port}";
      };

      systemd.services = {
        lidarr = {
          # fpcalc fingerprints badly tagged files; the package does not ship it.
          path = [ pkgs.chromaprint ];

          # The library watcher is created once at start and never retried; before the mount it dies.
          unitConfig.RequiresMountsFor = [ "/tank/media" ];

          # No login on the tailnet, so a UI click must not reach the rest of what soft owns.
          serviceConfig = {
            ProtectSystem = "strict";
            ProtectHome = true;
            # SQLite spills statement journals to /tmp, read-only under strict.
            PrivateTmp = true;
            ReadWritePaths = [
              config.services.lidarr.dataDir
              "/tank/media/music"
              "/tank/media/torrents"
            ];
            InaccessiblePaths = [ "/run/agenix.d" ];
          };
        };

        lidarr-setup = {
          description = "Declare Lidarr's indexer, download client and library";
          after = [ "lidarr.service" ];
          wantedBy = [ "lidarr.service" ];

          serviceConfig = {
            Type = "oneshot";
            ExecStart = lib.getExe lidarr-setup;
            # soft owns the c411 key.
            User = "soft";
            # Oneshots have no start timeout by default; the wait loops would hang silently.
            TimeoutStartSec = "5min";
          };
        };
      };
    };
}
