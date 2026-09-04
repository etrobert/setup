_: {
  perSystem =
    { pkgs, ... }:
    {
      packages.nix-dead-sweep = pkgs.writeShellApplication {
        name = "nix-dead-sweep";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.git
          pkgs.jq
          pkgs.nix
        ];
        inheritPath = false;
        text = builtins.readFile ./nix-dead-sweep.sh;
      };
    };
}
