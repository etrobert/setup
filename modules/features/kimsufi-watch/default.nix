# Notify when a Kimsufi with 4 TB or more becomes orderable, so charon could be
# replaced by a box that holds the media library itself.
#
# The range's own pages are no guide: every model reads "Bald verfügbar" while
# stock rotates per datacenter underneath. OVH publishes the live state
# unauthenticated at /dedicated/server/datacenter/availabilities, which is the
# only source that distinguishes "sold out" from "deliverable in 72H".
{ self, ... }:
{
  perSystem =
    { pkgs, self', ... }:
    {
      packages.kimsufi-watch = pkgs.writeShellApplication {
        name = "kimsufi-watch";

        runtimeInputs = [
          pkgs.coreutils
          pkgs.curl
          pkgs.jq
          self'.packages.ntfy-wrapped
        ];

        inheritPath = false;
        text = builtins.readFile ./watch.sh;
      };
    };

  flake.nixosModules.kimsufiWatch =
    { pkgs, lib, ... }:
    {
      systemd = {
        services.kimsufi-watch = {
          description = "Notify when a large-disk Kimsufi becomes orderable";

          # Persistent=true fires the missed run at boot, before DNS resolves.
          after = [ "network-online.target" ];
          wants = [ "network-online.target" ];

          serviceConfig = {
            Type = "oneshot";
            StateDirectory = "kimsufi-watch";
            ExecStart = lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.kimsufi-watch;
          };
        };

        timers.kimsufi-watch = {
          description = "Schedule the Kimsufi availability poll";
          wantedBy = [ "timers.target" ];

          timerConfig = {
            OnCalendar = "*:0/30";
            Persistent = true;
          };
        };
      };
    };
}
