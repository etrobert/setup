# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ self, ... }:

{
  flake.nixosModules.leodConfiguration =
    { config, pkgs, ... }:
    {
      imports = [ self.nixosModules.leodHardware ];

      boot.kernelParams = [ "mem_sleep_default=deep" ];

      boot.loader = {
        systemd-boot.configurationLimit = 1;

        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
      };

      networking.hostName = "leod"; # Define your hostname.

      services.fprintd.enable = true;

      # The Synaptics Prometheus (06cb:00bd) does not survive suspend: it comes
      # back reporting an unsupported firmware version, stranding whatever
      # verify the lock screen had in flight. fprintd cannot cancel that one,
      # and its SIGTERM handler cannot break the loop it waits in, so it
      # refuses every later Claim until something kills it. Re-probing on
      # resume USB-resets the reader and drops the stale claim; the timeout
      # keeps a wedged instance from holding up shutdown for the default 90s.
      systemd.services.fprintd.serviceConfig.TimeoutStopSec = 5;

      powerManagement.resumeCommands = "${pkgs.systemd}/bin/systemctl try-restart fprintd.service";

      # Noctalia's lock screen drives the reader itself and authenticates against
      # `login`; pam_fprintd there re-claims that device and stalls the password path.
      security.pam.services.login.fprintAuth = false;

      # greetd's stack is only a substack of `login`, so the line above would take
      # tuigreet's fingerprint login with it. Give greetd its own copy instead.
      security.pam.services.greetd.rules.auth.fprintd = {
        order = config.security.pam.services.greetd.rules.auth.login.order - 10;
        control = "sufficient";
        modulePath = "${config.services.fprintd.package}/lib/security/pam_fprintd.so";
      };

      hardware.graphics.extraPackages = with pkgs; [ intel-media-driver ];

      # This value determines the NixOS release from which the default
      # settings for stateful data, like file locations and database versions
      # on your system were taken. It‘s perfectly fine and recommended to leave
      # this value at the release version of the first install of this system.
      # Before changing this value read the documentation for this option
      # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
      system.stateVersion = "25.11"; # Did you read the comment?
    };
}
