_: {
  perSystem =
    { pkgs, ... }:
    {
      packages.c411 = pkgs.writeShellApplication {
        name = "c411";

        runtimeInputs = with pkgs; [
          curl
          fzf
          transmission_4
          xidel
        ];

        inheritPath = false;

        text = builtins.readFile ./c411.sh;
      };
    };
}
