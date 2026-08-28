{
  lib,
  writeShellApplication,
  jq,
  niri,
  gawk,
}:
writeShellApplication {
  name = "scale-floating-window";
  meta.platforms = lib.platforms.linux;
  runtimeInputs = [
    jq
    niri
    gawk
  ];
  inheritPath = false;
  text = builtins.readFile ./scale-floating-window;
}
