# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ self, ... }:

{
  flake.nixosModules.leod-configuration =
    { config, pkgs, ... }:
    {
      imports = [ self.nixosModules.leod-hardware ];

      boot.kernelParams = [ "mem_sleep_default=deep" ];

      boot.loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
      };

      networking.hostName = "leod"; # Define your hostname.

      # Intel UHD 620 (i915).
      gpu = {
        hasAv1Decode = false;
        hasVramStat = false;
      };

      autoBrightness = {
        day = 100;
        night = 30;
      };

      age.secrets = {
        syncthing-cert.file = ../../../secrets/syncthing-leod-cert.age;
        syncthing-key.file = ../../../secrets/syncthing-leod-key.age;
        ssh-key = {
          file = ../../../secrets/ssh-soft-leod.age;
          owner = "soft";
        };
        disk-passphrase.file = ../../../secrets/leod-disk-passphrase.age;
        tpm-pin.file = ../../../secrets/leod-tpm-pin.age;
      };

      preservation = {
        enable = true;
        preserveAt."/persist" = {
          files = [
            {
              file = "/etc/machine-id";
              inInitrd = true;
            }
          ];
          directories = [
            {
              directory = "/var/lib/nixos";
              inInitrd = true;
            }
            {
              directory = "/var/lib/tailscale";
              mode = "0700";
            }
            {
              directory = "/var/lib/bluetooth";
              mode = "0700";
            }
            {
              directory = "/var/lib/fprint";
              mode = "0700";
            }
            "/var/lib/systemd/timers"
            "/var/lib/systemd/backlight"
            "/var/log"
            "/var/lib/flatpak"
          ];
        };
      };

      # Not linked into ~/.ssh: agenix would create the directory as root.
      programs.ssh.extraConfig = "IdentityFile ${config.age.secrets.ssh-key.path}";

      services = {
        fprintd.enable = true;

        # agenix reads its identity from here before bind mounts exist (https://github.com/ryantm/agenix/issues/219).
        openssh.hostKeys = [
          {
            path = "/persist/etc/ssh/ssh_host_ed25519_key";
            type = "ed25519";
          }
        ];

        # leod is the only host that travels, so it geolocates its timezone
        # instead of pinning one. The module sets time.timeZone to null.
        automatic-timezoned.enable = true;

        # The disk unlock already authenticated the boot; tuigreet stays for logouts.
        greetd.settings.initial_session = {
          user = "soft";
          command = "niri-session";
        };

        # Keeps the device ID pinned in syncthing-settings.nix across reinstalls.
        syncthing = {
          cert = config.age.secrets.syncthing-cert.path;
          key = config.age.secrets.syncthing-key.path;
        };
      };

      systemd = {
        # Fails on a bind-mounted /etc/machine-id (preservation docs/src/examples.md).
        suppressedSystemUnits = [ "systemd-machine-id-commit.service" ];

        # Syncthing installs cert/key as root, which would create a missing ~/.config root-owned.
        tmpfiles.settings.home-config."/home/soft/.config".d = {
          user = "soft";
          group = "users";
          mode = "0755";
        };

        # If the TPM stops unlocking after a firmware change: systemd-cryptenroll --wipe-slot=tpm2, reboot.
        services.tpm2-enroll = {
          wantedBy = [ "multi-user.target" ];
          path = [
            pkgs.cryptsetup
            config.systemd.package
          ];
          serviceConfig.Type = "oneshot";
          script =
            let
              device = config.boot.initrd.luks.devices.root.device;
            in
            ''
              if cryptsetup luksDump ${device} | grep --quiet systemd-tpm2; then
                exit 0
              fi
              NEWPIN=$(cat ${config.age.secrets.tpm-pin.path}) systemd-cryptenroll \
                --unlock-key-file=${config.age.secrets.disk-passphrase.path} \
                --tpm2-device=auto --tpm2-pcrs=7 --tpm2-with-pin=yes ${device}
            '';
        };
      };

      # The Synaptics Prometheus (06cb:00bd) does not survive suspend: it comes
      # back reporting an unsupported firmware version, stranding whatever
      # verify the lock screen had in flight. fprintd cannot cancel that one,
      # and its SIGTERM handler cannot break the loop it waits in, so it
      # refuses every later Claim until something kills it. Re-probing on
      # resume USB-resets the reader and drops the stale claim; the timeout
      # keeps a wedged instance from holding up shutdown for the default 90s.
      systemd.services.fprintd.serviceConfig.TimeoutStopSec = 5;

      powerManagement.resumeCommands = "${pkgs.systemd}/bin/systemctl try-restart fprintd.service";

      # pam_fprintd is serial: it holds the prompt for its full timeout — 30s
      # by default — before the typed password is even considered.
      security.pam.services = {
        # Noctalia's lock screen authenticates against the login stack and
        # drives fprintd over D-Bus alongside its password field, so the module
        # must not be in it — the same call gdm and plasma6 make in nixpkgs.
        login.fprintAuth = false;

        sudo.rules.auth.fprintd.settings.timeout = 5;
        "polkit-1".rules.auth.fprintd.settings.timeout = 5;
        su.rules.auth.fprintd.settings.timeout = 5;
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
