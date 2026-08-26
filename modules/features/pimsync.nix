_: {
  flake.nixosModules.pimsync =
    {
      self,
      pkgs,
      lib,
      ...
    }:
    let
      pimsync = self.packages.${pkgs.stdenv.hostPlatform.system}.pimsync-wrapped;
    in
    {
      age.secrets.apple-pimsync-password = {
        owner = "soft";
        file = ../../secrets/apple-pimsync-password.age;
      };

      environment.systemPackages = [ pimsync ];

      systemd.user.services.pimsync = {
        description = "pimsync calendar and contacts synchronization";
        partOf = [ "network-online.target" ];
        after = [ "run-agenix.d.mount" ];
        wantedBy = [ "default.target" ];
        unitConfig.ConditionUser = "!@system";
        serviceConfig = {
          Type = "simple";
          ExecStart = "${lib.getExe pimsync} -v info daemon";
        };
      };
    };
}
