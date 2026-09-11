{ self, ... }:
{
  flake.nixosModules.screenWatch =
    { pkgs, lib, ... }:
    {
      systemd.user.services.screen-watch = {
        description = "Notify when a template image shows up in a window";
        after = [ "graphical-session.target" ];
        partOf = [ "graphical-session.target" ];
        wantedBy = [ "graphical-session.target" ];

        serviceConfig = {
          ExecStart = lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.screen-watch;
          Restart = "on-failure";
          RestartSec = 10;
        };
      };
    };
}
