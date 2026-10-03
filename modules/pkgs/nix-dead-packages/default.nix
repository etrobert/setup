_: {
  perSystem =
    { pkgs, ... }:
    {
      packages.nix-dead-packages = pkgs.writeShellApplication {
        name = "nix-dead-packages";
        runtimeInputs = with pkgs; [
          coreutils
          findutils
          gawk
          git
          jq
          nix
          nix-eval-jobs
        ];
        inheritPath = false;
        text = builtins.readFile ./nix-dead-packages.sh;
      };
    };
}
