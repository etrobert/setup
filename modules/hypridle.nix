_: {
  flake.nixosModules.hypridle =
    {
      self,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (pkgs.stdenv.hostPlatform) system;
      inherit (self.packages.${system}) hypridle-wrapped;
    in
    {
      environment.systemPackages = [ hypridle-wrapped ];

      # Source: https://github.com/nix-community/home-manager/blob/master/modules/services/hypridle.nix
      systemd.user.services.hypridle = {
        description = "Hypridle idle daemon";
        after = [ "graphical-session.target" ];
        partOf = [ "graphical-session.target" ];
        bindsTo = [ "graphical-session.target" ];
        wantedBy = [ "graphical-session.target" ];
        serviceConfig = {
          ExecStart = "${lib.getExe hypridle-wrapped}";
          Restart = "on-failure";
        };
      };
    };
}
