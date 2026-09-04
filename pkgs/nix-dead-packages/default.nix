_: {
  perSystem =
    { pkgs, ... }:
    {
      packages.nix-dead-packages = pkgs.writeShellApplication {
        name = "nix-dead-packages";
        runtimeInputs = with pkgs; [
          coreutils
          gawk
          git
          jq
          nix
        ];
        inheritPath = false;
        text = builtins.readFile ./nix-dead-packages.sh;
      };
    };
}
