{ pkgs }:
pkgs.writeShellApplication {
  name = "pm";
  runtimeInputs = with pkgs; [
    bashInteractive # provides sh for npm to spawn scripts
    coreutils
    nodejs_24 # nodejs_latest does not always have cache ready
    pnpm
    yarn
  ];
  inheritPath = true; # It may run anything through a npm script or vite thingy
  text = builtins.readFile ./pm.sh;
}
