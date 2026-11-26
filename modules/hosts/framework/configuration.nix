{ self, ... }:
{
  flake.nixosModules.framework-configuration =
    { pkgs, ... }:
    {
      imports = [ self.nixosModules.framework-hardware ];

      boot.loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
      };

      networking.hostName = "framework";

      # Intel Arc B390 (xe); exposes no VRAM statistic as an integrated GPU.
      gpu.hasVramStat = false;

      autoBrightness = {
        day = 100;
        night = 30;
      };

      services = {
        fprintd.enable = true;
        automatic-timezoned.enable = true;
      };

      hardware.graphics.extraPackages = [ pkgs.intel-media-driver ];

      system.stateVersion = "26.11";
    };
}
