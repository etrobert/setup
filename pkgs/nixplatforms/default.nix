_: {
  perSystem =
    { pkgs, ... }:
    {
      packages.nixplatforms = pkgs.writeShellApplication {
        name = "nixplatforms";
        runtimeInputs = [ pkgs.nix ];
        inheritPath = false;
        text = ''
          nix eval nixpkgs#"$1".meta.platforms --json
        '';
      };
    };
}
