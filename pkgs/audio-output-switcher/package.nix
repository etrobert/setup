{ pkgs, fzf-wrapped, ... }:
pkgs.writeShellApplication {
  name = "audio-output-switcher";
  meta.platforms = pkgs.lib.platforms.linux;
  runtimeInputs = with pkgs; [
    coreutils # cut
    fzf-wrapped
    jq
    libnotify
    pipewire # provides pw-dump
    wireplumber # provides wpctl
  ];
  inheritPath = false;
  text = builtins.readFile ./audio-output-switcher;
}
