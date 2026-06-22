# darwin syncthing: launchd user agents replacing home-manager services.syncthing.
#
# nix-darwin has no services.syncthing, so two agents are used:
#   • syncthing      – keeps the daemon running (KeepAlive = true)
#   • syncthing-init – one-shot: waits for the daemon, then applies the
#                      declarative device/folder/options/gui config via the
#                      syncthing REST API.
#
# Settings are imported from lib/syncthing-settings.nix — same source as the
# NixOS systemd syncthing-init unit in modules/nixos-base.nix.
#
# Config dir: /Users/soft/Library/Application Support/Syncthing
# (macOS default; matches the path home-manager's services.syncthing used).
# syncthing-init reads the auto-generated API key from config.xml, waits for
# the HTTP API to come up, then:
#   - PUT  /rest/config/devices and /rest/config/folders (declarative array replace)
#   - PATCH /rest/config/options and /rest/config/gui (merge, preserves other fields)
#   - POST /rest/db/ignores?folder=<id> for each folder with ignorePatterns
# Re-run after a settings change: launchctl kickstart gui/<uid>/com.local.syncthing-init
{
  self,
  pkgs,
  lib,
  ...
}:
let
  dataDir = "/Users/soft";
  syncthingHome = "${dataDir}/Library/Application Support/Syncthing";

  settings = import (self + /lib/syncthing-settings.nix) { inherit dataDir; };

  devicesJSON = pkgs.writeText "syncthing-devices.json" (
    builtins.toJSON (
      lib.mapAttrsToList (name: device: {
        deviceID = device.id;
        inherit name;
      }) settings.devices
    )
  );

  foldersJSON = pkgs.writeText "syncthing-folders.json" (
    builtins.toJSON (
      lib.mapAttrsToList (
        id: folder:
        # ignorePatterns is intentionally excluded — it is not a valid
        # folder-config field; it is pushed separately via /rest/db/ignores.
        {
          inherit id;
          inherit (folder) path;
          devices = map (deviceName: {
            deviceID = settings.devices.${deviceName}.id;
          }) folder.devices;
        }
        // lib.optionalAttrs (folder ? versioning) { inherit (folder) versioning; }
      ) settings.folders
    )
  );

  optionsJSON = pkgs.writeText "syncthing-options.json" (builtins.toJSON settings.options);

  guiJSON = pkgs.writeText "syncthing-gui.json" (builtins.toJSON settings.gui);

  # Per-folder ignore-pattern payloads, sourced from lib/syncthing-settings.nix.
  # Only built for folders that declare ignorePatterns.
  folderIgnoreFiles = lib.mapAttrsToList (id: folder: {
    inherit id;
    jsonFile = pkgs.writeText "syncthing-ignore-${id}.json" (
      builtins.toJSON { ignore = folder.ignorePatterns; }
    );
  }) (lib.filterAttrs (_: folder: folder ? ignorePatterns) settings.folders);

  syncthingInit = pkgs.writeShellApplication {
    name = "syncthing-init";
    runtimeInputs = [ pkgs.curl ];
    inheritPath = false;
    text = ''
      CONFIG_FILE="${syncthingHome}/config.xml"
      API_URL="http://127.0.0.1:8384"

      # Wait for syncthing to generate its config (contains the auto-created API key)
      until [ -f "$CONFIG_FILE" ]; do
        sleep 1
      done

      API_KEY=$(grep --only-matching '<apikey>[^<]*' "$CONFIG_FILE" | sed 's/<apikey>//')

      # Wait for the HTTP API to become available
      until curl --silent --fail "$API_URL/rest/noauth/health" > /dev/null 2>&1; do
        sleep 2
      done

      # PUT replaces the full array — acceptable for devices and folders.
      put() {
        curl --silent --fail \
          --header "X-API-Key: $API_KEY" \
          --header "Content-Type: application/json" \
          --request PUT \
          --data "@$1" \
          "$API_URL$2"
      }

      # PATCH merges into the singleton section, preserving fields we don't set
      # (e.g. gui.apiKey).
      patch() {
        curl --silent --fail \
          --header "X-API-Key: $API_KEY" \
          --header "Content-Type: application/json" \
          --request PATCH \
          --data "@$1" \
          "$API_URL$2"
      }

      put ${devicesJSON} /rest/config/devices
      put ${foldersJSON} /rest/config/folders
      patch ${optionsJSON} /rest/config/options
      patch ${guiJSON} /rest/config/gui

      ${lib.concatMapStrings ({ id, jsonFile }: ''
        curl --silent --fail \
          --header "X-API-Key: $API_KEY" \
          --header "Content-Type: application/json" \
          --request POST \
          --data "@${jsonFile}" \
          "$API_URL/rest/db/ignores?folder=${id}"
      '') folderIgnoreFiles}
    '';
  };
in
{
  launchd.user.agents = {
    syncthing.serviceConfig = {
      ProgramArguments = [
        "${lib.getExe pkgs.syncthing}"
        "-no-browser"
        "-no-default-folder"
        "-gui-address=0.0.0.0:8384"
        "-home=${syncthingHome}"
      ];
      KeepAlive = true;
      RunAtLoad = true;
      StandardOutPath = "/tmp/syncthing.log";
      StandardErrorPath = "/tmp/syncthing.log";
    };

    syncthing-init.serviceConfig = {
      ProgramArguments = [ "${lib.getExe syncthingInit}" ];
      RunAtLoad = true;
      StandardOutPath = "/tmp/syncthing-init.log";
      StandardErrorPath = "/tmp/syncthing-init.log";
    };
  };
}
