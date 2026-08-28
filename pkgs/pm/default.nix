_: {
  perSystem =
    { pkgs, ... }:
    {
      packages.pm = pkgs.writeShellApplication {
        name = "pm";
        runtimeInputs = [
          pkgs.bashInteractive # provides sh for npm to spawn scripts
          pkgs.coreutils
        ];
        inheritPath = true; # It may run anything through a npm script or vite thingy
        text = builtins.readFile ./pm.sh;
      };
    };
}
