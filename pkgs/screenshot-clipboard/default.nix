{
  writeShellApplication,
  grim,
  slurp,
  wl-clipboard,
  libnotify,
}:
writeShellApplication {
  name = "screenshot-clipboard";
  runtimeInputs = [
    grim
    slurp
    wl-clipboard
    libnotify
  ];
  inheritPath = false;
  text = builtins.readFile ./screenshot-clipboard;
}
