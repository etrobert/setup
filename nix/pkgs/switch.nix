{
  coreutils,
  stdenv,
  writeShellApplication,
  runCommandLocal,
  inputs',
  nixos-rebuild,
  systemd,
}:
if stdenv.isLinux then
  let
    sudo = runCommandLocal "sudo" { } ''
      mkdir -p $out/bin
      ln -s /run/wrappers/bin/sudo $out/bin/sudo
    '';
  in
  writeShellApplication {
    name = "switch";
    runtimeInputs = [
      coreutils # for id
      sudo
      nixos-rebuild
      systemd
    ];
    inheritPath = false;
    text = "sudo nixos-rebuild switch";
  }
else
  let
    sudo = runCommandLocal "sudo" { } ''
      mkdir -p $out/bin
      ln -s /usr/bin/sudo $out/bin/sudo
    '';
  in
  writeShellApplication {
    name = "switch";
    runtimeInputs = [
      coreutils # for id
      sudo
      inputs'.nix-darwin.packages.darwin-rebuild
    ];
    inheritPath = false;
    text = "sudo darwin-rebuild switch";
  }
