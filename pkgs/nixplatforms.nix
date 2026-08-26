{ writeShellApplication, nix }:
writeShellApplication {
  name = "nixplatforms";
  runtimeInputs = [ nix ];
  inheritPath = false;
  text = /* bash */ ''
    nix eval nixpkgs#"$1".meta.platforms --json
  '';
}
