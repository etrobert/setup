{ pkgs }:
pkgs.writeShellApplication {
  name = "nixplatforms";
  runtimeInputs = with pkgs; [ nix ];
  inheritPath = false;
  text = ''
    nix eval nixpkgs#"$1".meta.platforms --json
  '';
}
