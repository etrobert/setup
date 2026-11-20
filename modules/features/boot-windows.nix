{ self, ... }:
{
  flake.nixosModules.boot-windows =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        (pkgs.writeShellApplication {
          name = "boot-windows";
          runtimeInputs = [
            self.packages.${pkgs.stdenv.hostPlatform.system}.setuid-sudo
          ]
          ++ (with pkgs; [
            efibootmgr
            gnugrep
            systemd
          ]);
          inheritPath = false;
          text = /* bash */ ''
            entry=$(efibootmgr | grep --only-matching --perl-regexp '(?<=^Boot)[0-9A-F]{4}(?=\*? Windows Boot Manager)')
            # BootNext applies to one boot, so the firmware's default order is left alone.
            sudo efibootmgr --bootnext "$entry"
            systemctl reboot
          '';
        })
      ];
    };
}
