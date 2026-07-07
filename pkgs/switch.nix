{ self', pkgs }:
let
  nhSubcommand = if pkgs.stdenv.isLinux then "os" else "darwin";
  flakePath = if pkgs.stdenv.isLinux then "/home/soft/setup" else "/Users/soft/setup";
in
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
  ]);
  inheritPath = false;
  text = "nh ${nhSubcommand} switch ${flakePath}";
}
