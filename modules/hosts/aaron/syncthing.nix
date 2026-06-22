# darwin syncthing: launchd user agents replacing home-manager services.syncthing.
#
# nix-darwin has no services.syncthing, so two agents are used:
#   • syncthing      – keeps the daemon running (KeepAlive = true)
#   • syncthing-init – one-shot: waits for the daemon, then PUTs the
#                      declarative device/folder/options/gui config via the
#                      syncthing REST API.
#
# Settings are imported from lib/syncthing-settings.nix — same source as the
# NixOS systemd syncthing-init unit in modules/nixos-base.nix.
#
# Config dir: /Users/soft/Library/Application Support/Syncthing
# (macOS default; matches the path home-manager's services.syncthing used).
# syncthing-init reads the auto-generated API key from config.xml, waits for
# the HTTP API to come up, then PUTs devices, folders, options and GUI settings.
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

      put() {
        curl --silent --fail \
          --header "X-API-Key: $API_KEY" \
          --header "Content-Type: application/json" \
          --request PUT \
          --data "@$1" \
          "$API_URL$2"
      }

      put ${devicesJSON} /rest/config/devices
      put ${foldersJSON} /rest/config/folders
      put ${optionsJSON} /rest/config/options
      put ${guiJSON} /rest/config/gui
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
