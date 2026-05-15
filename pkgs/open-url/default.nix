{
  writeShellApplication,
  jq,
  self',
}:
writeShellApplication {
  name = "open-url";
  runtimeInputs = [
    jq
    self'.packages.niri-wrapped
    self'.packages.zen-browser-wrapped
  ];
  inheritPath = false;
  text = builtins.readFile ./open-url;
}
