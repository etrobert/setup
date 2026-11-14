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
      dir = "/home/${user}/sync/doc/inbox";
    in
    {
      ports.inbox = "auto";

      systemd.tmpfiles.rules = [ "d ${dir} 0755 ${user} users -" ];

      systemd.services.inbox = {
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          User = user;
          ExecStart = "${lib.getExe inbox} --port ${port} --dir ${dir}";
          Restart = "on-failure";
        };
      };

      services.tsnsrv.services.inbox.toURL = "http://127.0.0.1:${port}";
    };
}
