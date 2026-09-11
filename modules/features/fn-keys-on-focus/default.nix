{ self, ... }:
{
  perSystem =
    {
      pkgs,
      lib,
      ...
    }:
    {
      packages = self.lib.onlySupported {
        fn-keys-on-focus = pkgs.writeShellApplication {
          name = "fn-keys-on-focus";
          meta.platforms = lib.platforms.linux;
          runtimeInputs = with pkgs; [
            jq
            niri
          ];
          inheritPath = false;
          text = builtins.readFile ./fn-keys-on-focus.sh;
        };
      };
    };

  flake.nixosModules.fn-keys-on-focus =
    {
      lib,
      pkgs,
      utils,
      ...
    }:
    let
      inherit (pkgs.stdenv.hostPlatform) system;
      inherit (self.packages.${system}) fn-keys-on-focus;
    in
    {
      # The user service below writes the parameter, so it must not be root-only.
      services.udev.extraRules = ''
        ACTION=="add", SUBSYSTEM=="module", KERNEL=="hid_apple", RUN+="${pkgs.coreutils}/bin/chmod 0666 /sys/module/hid_apple/parameters/fnmode"
      '';

      systemd.user.services.fn-keys-on-focus = {
        description = "Put the Apple keyboard's F-keys first while a matching window is focused";
        after = [ "graphical-session.target" ];
        partOf = [ "graphical-session.target" ];
        wantedBy = [ "graphical-session.target" ];

        serviceConfig = {
          ExecStart = utils.escapeSystemdExecArgs [
            (lib.getExe fn-keys-on-focus)
            ''^Dofus\.x64$''
          ];
          Restart = "on-failure";
        };
      };
    };
}
