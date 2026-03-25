{ pkgs }:
pkgs.writeShellApplication {
  name = "brightness-control";
  runtimeInputs = with pkgs; [
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
