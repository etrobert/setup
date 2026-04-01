{
  coreutils,
  stdenv,
  writeShellApplication,
  runCommandLocal,
  inputs',
  lib,
}:
let
  sudo-path = if stdenv.isDarwin then "/usr/bin/sudo" else "/run/wrappers/bin/sudo";

  sudo-wrapped = runCommandLocal "sudo" { } ''
    mkdir -p $out/bin
    ln -s ${sudo-path} $out/bin/sudo
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
