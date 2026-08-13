{ self', pkgs }:
pkgs.writeShellApplication {
  name = "switch";
  # nh calls `sudo env nixos-rebuild ...`; all three must be in PATH so nh
  # can resolve them to absolute store paths before invoking sudo
  runtimeInputs = [
    self'.packages.setuid-sudo
  ]
  ++ (with pkgs; [
    coreutils
    nh
    nix
  ])
  ++ pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.util-linux ];
  inheritPath = false;
  text =
    if pkgs.stdenv.hostPlatform.isLinux then
      /* bash */ ''
        # A stale /mnt/tank CIFS mount freezes PID 1 when the switch re-execs
        # systemd (NixOS/nixpkgs#375376); block only that combination.
        if findmnt --noheadings --types cifs /mnt/tank > /dev/null; then
          config="/home/soft/setup#nixosConfigurations.$(uname --nodename).config"

          current_systemd=$(realpath /run/current-system/systemd)
          new_systemd=$(nix eval --raw "$config.systemd.package.outPath")
          current_conf=$(realpath /etc/systemd/system.conf)
          new_conf=$(nix eval --raw "$config.environment.etc.\"systemd/system.conf\".source")

          if [ "$new_systemd" != "$current_systemd" ] || [ "$new_conf" != "$current_conf" ]; then
            echo "switch: re-execs systemd while /mnt/tank is mounted; unmount first: sudo umount /mnt/tank" >&2
            exit 1
          fi
        fi

        nh os switch --show-activation-logs /home/soft/setup
      ''
    else
      "nh darwin switch --show-activation-logs /Users/soft/setup";
}
