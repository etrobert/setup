{ pkgs }:
let
  # nixpkgs#sudo lacks the setuid bit (the Nix store is mounted nosuid).
  # On NixOS, the real setuid wrapper lives at /run/wrappers/bin/sudo.
  # On Darwin, nixpkgs#sudo is a Linux ELF binary that won't run on macOS;
  # the native sudo lives at /usr/bin/sudo.
  sudo =
    let
      path = if pkgs.stdenv.isLinux then "/run/wrappers/bin/sudo" else "/usr/bin/sudo";
    in
    pkgs.runCommandLocal "sudo" { } ''
      mkdir -p $out/bin
      ln -s ${path} $out/bin/sudo
    '';

  switch-linux = pkgs.writeShellApplication {
    name = "switch";
    # nh calls `sudo env nixos-rebuild ...`; all three must be in PATH so nh
    # can resolve them to absolute store paths before invoking sudo
    runtimeInputs = with pkgs; [
      coreutils
      nh
      nix
      sudo
    ];
    inheritPath = false;
    text = "nh os switch";
  };

  switch-darwin = pkgs.writeShellApplication {
    name = "switch";
    runtimeInputs = with pkgs; [
      coreutils
      nh
      nix
      sudo
    ];
    inheritPath = false;
    text = "nh darwin switch";
  };
in
if pkgs.stdenv.isLinux then switch-linux else switch-darwin
