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
          new_system=$(nix build --no-link --print-out-paths \
            "/home/soft/setup#nixosConfigurations.$(uname --nodename).config.system.build.toplevel")

          current_pid1=$(realpath /run/current-system/systemd/lib/systemd/systemd)
          new_pid1=$(realpath "$new_system/systemd/lib/systemd/systemd")
          current_conf=$(realpath /etc/systemd/system.conf)
          new_conf=$(realpath "$new_system/etc/systemd/system.conf")

          if [ "$new_pid1" != "$current_pid1" ] || [ "$new_conf" != "$current_conf" ]; then
            echo "switch: re-execs systemd while /mnt/tank is mounted; unmount first: sudo umount /mnt/tank" >&2
            exit 1
          fi
        fi

        nh os switch --show-activation-logs /home/soft/setup
      ''
    else
      "nh darwin switch --show-activation-logs /Users/soft/setup";
}
