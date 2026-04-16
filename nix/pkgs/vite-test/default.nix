{ pkgs, ... }:
pkgs.buildNpmPackage {
  name = "vite-test";
  src = ./.;
  npmDepsHash = "sha256-7Ik2hPGRwLDlRvC/Gne/BV8u29gxaIcwmLrGvNMhqj0=";
  installPhase = "cp -r dist $out";
}
