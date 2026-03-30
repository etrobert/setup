_: {
  flake.nixosModules.pimsync =
    { pkgs, lib, ... }:
    {
      age.secrets.apple-pimsync-password = {
        owner = "soft";
        file = ../secrets/apple-pimsync-password.age;
      };

      systemd.user.services.pimsync = {
        description = "pimsync calendar and contacts synchronization";
        partOf = [ "network-online.target" ];
        after = [ "run-agenix.d.mount" ];
        wantedBy = [ "default.target" ];
        serviceConfig = {
          Type = "simple";
          ExecStart = "${lib.getExe pkgs.pimsync} -v warn daemon";
        };
      };
    };
}
