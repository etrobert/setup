{ stdenv, writeShellApplication }:
writeShellApplication {
  name = "switch";
  runtimeInputs = [ ];
  inheritPath = false;
  text = if stdenv.isLinux then "sudo nixos-rebuild switch" else "sudo darwin-rebuild switch";
}
