{ pkgs }:
let
  switch-linux =
    let
      # nixpkgs#sudo lacks the setuid bit (the Nix store is mounted nosuid);
      # NixOS places the real setuid wrapper at /run/wrappers/bin/sudo
      sudo = pkgs.runCommandLocal "sudo" { } ''
        mkdir -p $out/bin
        ln -s /run/wrappers/bin/sudo $out/bin/sudo
      '';
    in
    pkgs.writeShellApplication {
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

  switch-darwin =
    let
      sudo = pkgs.runCommandLocal "sudo" { } ''
        mkdir -p $out/bin
        ln -s /usr/bin/sudo $out/bin/sudo
      '';
    in
    pkgs.writeShellApplication {
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
