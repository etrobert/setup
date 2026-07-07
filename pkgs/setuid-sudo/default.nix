{ runCommandLocal, stdenv }:
# nixpkgs#sudo lacks the setuid bit (the Nix store is mounted nosuid).
# On NixOS, the real setuid wrapper lives at /run/wrappers/bin/sudo.
# On Darwin, nixpkgs#sudo is a Linux ELF binary that won't run on macOS;
# the native sudo lives at /usr/bin/sudo.
let
  path = if stdenv.isLinux then "/run/wrappers/bin/sudo" else "/usr/bin/sudo";
in
runCommandLocal "setuid-sudo" { } ''
  mkdir -p $out/bin
  ln -s ${path} $out/bin/sudo
''
