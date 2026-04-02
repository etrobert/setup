_: {
  flake.nixosModules.darkman =
    { lib, pkgs, ... }:
    let
      inherit (pkgs) symlinkJoin makeWrapper writeTextDir;

      config = writeTextDir "darkman/config.yaml" /* yaml */ ''
        lat: 52.5
        lng: 13.4
        usegeoclue: true
      '';

      darkman = symlinkJoin {
        name = "darkman";
        nativeBuildInputs = [ makeWrapper ];
        paths = [ pkgs.darkman ];
        meta.mainProgram = "darkman";
        postBuild = ''
          XDG_CONFIG_HOME=${config} $out/bin/darkman check

          wrapProgram $out/bin/darkman \
            --set XDG_CONFIG_HOME ${config}
        '';
      };
    in
    {
      # Source: https://darkman.whynothugo.nl
      xdg.portal.config.niri."org.freedesktop.impl.portal.Settings" = "darkman";

      environment.systemPackages = [ darkman ];

      # Source: https://github.com/nix-community/home-manager/blob/d166a078541982a76f14d3e06e9665fa5c9ed85e/modules/services/darkman.nix
      systemd.user.services.darkman = {
        description = "Darkman system service";
        partOf = [ "graphical-session.target" ];
        bindsTo = [ "graphical-session.target" ];
        wantedBy = [ "graphical-session.target" ];
        serviceConfig = {
          Type = "dbus";
          BusName = "nl.whynothugo.darkman";
          ExecStart = "${lib.getExe darkman} run";
          Restart = "on-failure";
          TimeoutStopSec = 15;
          Slice = "background.slice";
        };
      };
    };
}
