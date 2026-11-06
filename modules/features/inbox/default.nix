{ self, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      packages.inbox = pkgs.buildGoModule {
        pname = "inbox";
        version = "0.1.0";
        src = ./.;
        # Standard library only, so there is no vendor directory to hash.
        vendorHash = null;
        meta.mainProgram = "inbox";
      };
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
      listen = "127.0.0.1:${toString config.ports.inbox}";
      dir = "/home/${user}/sync/doc/inbox";
    in
    {
      ports.inbox = "auto";

      systemd.tmpfiles.rules = [ "d ${dir} 0755 ${user} users -" ];

      systemd.services.inbox = {
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          User = user;
          ExecStart = "${lib.getExe inbox} -addr ${listen} -dir ${dir}";
          Restart = "on-failure";
        };
      };

      services.tsnsrv.services.inbox.toURL = "http://${listen}";
    };
}
