_: {
  perSystem =
    { pkgs, lib, ... }:
    {
      packages = lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
        darkman-wrapped =
          let
            config = pkgs.writeTextDir "darkman/config.yaml" /* yaml */ ''
              lat: 52.5
              lng: 13.4
              usegeoclue: true
            '';
          in
          pkgs.wrapPackage {
            package = pkgs.darkman;
            env.XDG_CONFIG_HOME = "${config}";
            # Fail the build on an invalid config rather than at service start-up.
            checks = [ "XDG_CONFIG_HOME=${config} $out/bin/darkman check" ];
          };
      };
    };

  flake.nixosModules.darkman =
    {
      self,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (pkgs.stdenv.hostPlatform) system;
      inherit (self.packages.${system}) darkman-wrapped;
    in
    {
      # Source: https://darkman.whynothugo.nl
      xdg.portal.config.niri."org.freedesktop.impl.portal.Settings" = "darkman";

      environment.systemPackages = [ darkman-wrapped ];

      # Source: https://github.com/nix-community/home-manager/blob/d166a078541982a76f14d3e06e9665fa5c9ed85e/modules/services/darkman.nix
      systemd.user.services.darkman = {
        description = "Darkman system service";
        after = [ "graphical-session.target" ];
        partOf = [ "graphical-session.target" ];
        bindsTo = [ "graphical-session.target" ];
        wantedBy = [ "graphical-session.target" ];
        serviceConfig = {
          Type = "dbus";
          BusName = "nl.whynothugo.darkman";
          ExecStart = "${lib.getExe darkman-wrapped} run";
          Restart = "on-failure";
          TimeoutStopSec = 15;
          Slice = "background.slice";
        };
      };
    };
}
