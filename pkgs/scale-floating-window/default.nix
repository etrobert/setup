{
  writeShellApplication,
  jq,
  niri,
  gawk,
}:
writeShellApplication {
  name = "scale-floating-window";
  runtimeInputs = [
    jq
    niri
    gawk
  ];
  inheritPath = false;
  text = builtins.readFile ./scale-floating-window;
}
