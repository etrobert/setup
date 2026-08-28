# Poll Kleinanzeigen for listings matching a private watch list and push each
# new hit to ntfy.
#
# Listings come from the Android app's JSON API rather than the website: it is
# unauthenticated, returns full descriptions and coordinates per ad, and needs
# no HTML parsing. The Basic credentials in watch.sh are the app's own static
# token (android:TaR60pEttY), not a personal one — see
# https://gist.github.com/BastelPichi/43e441f166fcd6a4c76f875dcbb91d5c
#
# The watch list and origin coordinates stay out of this repo, which is public.
{ self, ... }:
{
  perSystem =
    { pkgs, self', ... }:
    {
      packages.kleinanzeigen-watch = pkgs.writeShellApplication {
        name = "kleinanzeigen-watch";

        runtimeInputs = [
          pkgs.coreutils
          pkgs.curl
          pkgs.gnugrep
          pkgs.jq
          self'.packages.ntfy-wrapped
        ];

        inheritPath = false;
        text = builtins.readFile ./watch.sh;
      };
    };

  flake.nixosModules.kleinanzeigenWatch =
    { pkgs, lib, ... }:
    {
      systemd = {
        services.kleinanzeigen-watch = {
          description = "Notify about new Kleinanzeigen listings matching the watch list";

          serviceConfig = {
            Type = "oneshot";
            StateDirectory = "kleinanzeigen-watch";
            ExecStart = lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.kleinanzeigen-watch;
          };
        };

        # z (adjust-if-exists), not d: /tank is a nofail mount, and a boot
        # without the pool must not create this path on the root filesystem.
        # Create it once with `mkdir`; ownership is what this rule maintains.
        tmpfiles.settings.kleinanzeigen."/tank/kleinanzeigen".z = {
          user = "soft";
          group = "users";
          mode = "0700";
        };

        timers.kleinanzeigen-watch = {
          description = "Schedule the Kleinanzeigen watch-list poll";
          wantedBy = [ "timers.target" ];

          timerConfig = {
            OnCalendar = "*:0/15";
            Persistent = true;
          };
        };
      };
    };
}
