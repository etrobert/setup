{
  writeShellApplication,
  coreutils,
  brightnessctl,
  libnotify,
}:
writeShellApplication {
  name = "brightness-control";
  runtimeInputs = [
    coreutils # cut & tr
    brightnessctl
    libnotify
  ];
  inheritPath = false;
  text = builtins.readFile ./brightness-control;
}
