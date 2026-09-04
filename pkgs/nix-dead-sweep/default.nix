_: {
  perSystem =
    { pkgs, ... }:
    {
      packages.nix-dead-sweep = pkgs.writeShellApplication {
        name = "nix-dead-sweep";
        runtimeInputs = with pkgs; [
          coreutils
          git
          gnused
          jq
          nix
        ];
        inheritPath = false;
        text = builtins.readFile ./nix-dead-sweep.sh;
      };
    };
}
