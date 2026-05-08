{ pkgs, ... }:
pkgs.writeShellApplication {
  name = "audio-output-switcher";
  runtimeInputs = with pkgs; [
    coreutils # cut
    fzf
    jq
    libnotify
    pipewire # provides pw-dump
    wireplumber # provides wpctl
  ];
  inheritPath = false;
  text = builtins.readFile ./audio-output-switcher;
}
