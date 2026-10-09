# A daily newsletter issue researched by Claude Code, published as an Atom feed
# on loopback for Miniflux to subscribe to.
{ self, ... }:
{
  perSystem =
    { pkgs, self', ... }:
    {
      packages.newsletter = pkgs.writeShellApplication {
        name = "newsletter";

        # Also the tools claude's Bash calls get.
        runtimeInputs = [
          pkgs.coreutils
          pkgs.curl
          pkgs.gnugrep
          pkgs.gnused
          pkgs.jq
          self'.packages.claude-code-wrapped
        ];

        runtimeEnv.NEWSLETTER_PROMPT = ./prompt.md;

        inheritPath = false;
        text = builtins.readFile ./newsletter.sh;
      };
    };

  flake.nixosModules.newsletter =
    { pkgs, lib, ... }:
    {
      imports = [ self.nixosModules.caddy ];

      systemd = {
        services.newsletter = {
          description = "Write today's newsletter issue";

          # Persistent=true fires the missed run at boot, before DNS resolves.
          after = [ "network-online.target" ];
          wants = [ "network-online.target" ];

          serviceConfig = {
            Type = "oneshot";
            # Owner of the Claude credentials the wrapped claude reads from $HOME.
            User = "soft";
            StateDirectory = "newsletter";
            ExecStart = lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.newsletter;
            # A hung run would otherwise block every later one.
            TimeoutStartSec = "1h";
          };
        };

        timers.newsletter = {
          description = "Schedule the daily newsletter issue";
          wantedBy = [ "timers.target" ];

          timerConfig = {
            OnCalendar = "*-*-* 06:00:00";
            Persistent = true;
          };
        };
      };

      services.caddy.virtualHosts."http://127.0.0.1:8086".extraConfig = /* caddy */ ''
        bind 127.0.0.1
        root * /var/lib/newsletter/public
        file_server
      '';
    };
}
