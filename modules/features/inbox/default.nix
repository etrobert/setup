# Quick-capture inbox, reachable on the tailnet as `inbox/`.
# Each capture is appended to a Markdown file in the Syncthing folder.
{ self, ... }:
{
  perSystem =
    { self', ... }:
    {
      packages.inbox = self'.legacyPackages.writers.writeTsBin "inbox" { } (builtins.readFile ./inbox.ts);
    };

  flake.nixosModules.inbox =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      user = "soft";
      inbox = self.packages.${pkgs.stdenv.hostPlatform.system}.inbox;
      port = toString config.ports.inbox;
    in
    {
      ports.inbox = "auto";

      systemd.services.inbox = {
        description = "Quick-capture inbox";
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          User = user;
          ExecStart = "${lib.getExe inbox} --port ${port} --file /home/${user}/sync/doc/inbox.md";
          Restart = "on-failure";
        };
      };

      services.tsnsrv.services.inbox.toURL = "http://127.0.0.1:${port}";
    };
}
