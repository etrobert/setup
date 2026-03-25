{
  writeShellApplication,
  coreutils,
  brightnessctl,
  hyprland,
  libnotify,
  gnugrep,
  jq,
}:
writeShellApplication {
  name = "brightness-control";
  runtimeInputs = [
    coreutils # cut & tr
    brightnessctl
    hyprland
    libnotify
    gnugrep
    jq
  ];
  inheritPath = false;
  text = builtins.readFile ./brightness-control;
}
