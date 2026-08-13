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
        # systemd (NixOS/nixpkgs#375376), so refuse to switch while it's mounted.
        if findmnt --noheadings --types cifs /mnt/tank > /dev/null; then
          echo "switch: /mnt/tank is mounted; unmount first: sudo umount /mnt/tank" >&2
          exit 1
        fi

        nh os switch --show-activation-logs /home/soft/setup
      ''
    else
      "nh darwin switch --show-activation-logs /Users/soft/setup";
}
