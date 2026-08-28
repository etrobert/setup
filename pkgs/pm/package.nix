{
  writeShellApplication,
  bashInteractive,
  coreutils,
}:
writeShellApplication {
  name = "pm";
  runtimeInputs = [
    bashInteractive # provides sh for npm to spawn scripts
    coreutils
  ];
  inheritPath = true; # It may run anything through a npm script or vite thingy
  text = builtins.readFile ./pm.sh;
}
