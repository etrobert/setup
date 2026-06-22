{
  writeShellApplication,
  bashInteractive,
  coreutils,
  nodejs_26,
  pnpm,
  yarn,
}:
writeShellApplication {
  name = "pm";
  runtimeInputs = [
    bashInteractive # provides sh for npm to spawn scripts
    coreutils
    nodejs_26 # pinned (not nodejs_latest) so the binary cache stays reliable
    pnpm
    yarn
  ];
  inheritPath = true; # It may run anything through a npm script or vite thingy
  text = builtins.readFile ./pm.sh;
}
