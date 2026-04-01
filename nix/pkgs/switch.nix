{
  coreutils,
  stdenv,
  writeShellApplication,
  sudo,
  runCommandLocal,
  inputs',
  lib,
}:
let
  sudo-wrapped =
    if stdenv.isLinux then
      sudo
    else
      runCommandLocal "sudo" { } ''
        mkdir -p $out/bin
        ln -s /usr/bin/sudo $out/bin/sudo
      '';
in
writeShellApplication {
  name = "switch";
  runtimeInputs = [
    coreutils # for id
    sudo-wrapped
  ]
  ++ lib.optionals stdenv.isDarwin [
    inputs'.nix-darwin.packages.darwin-rebuild
  ];
  inheritPath = false;
  text = if stdenv.isLinux then "sudo nixos-rebuild switch" else "sudo darwin-rebuild switch";
}
