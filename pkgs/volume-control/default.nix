{ pkgs, ... }:
pkgs.writeShellApplication {
  name = "volume-control";
  runtimeInputs = with pkgs; [
    gawk
    gnugrep
    libnotify
    wireplumber
  ];
  inheritPath = false;
  text = builtins.readFile ./volume-control;
}
