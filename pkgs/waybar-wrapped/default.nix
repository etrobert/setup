{
  self',
  pkgs,
  wrapPackage,
  dev ? false,
}:
let
  path = "/home/soft/setup/pkgs/waybar-wrapped";
  config = if dev then path + "/config.jsonc" else ./config.jsonc;
  style = if dev then path + "/style.css" else ./style.css;
  nixpkgsDeps = with pkgs; [
    coreutils
    jq # used by custom/weekday and custom/cpu-governor
    gawk # used by custom/cpu-freq
    pavucontrol
    playerctl # used by mpris on-click
  ];
in
wrapPackage {
  package = pkgs.waybar;
  flags = [
    "--config ${config}"
    "--style ${style}"
  ];
  runtimeInputs = [
    self'.packages.get-weather
    self'.packages.toggle-cpu-governor
    self'.packages.setuid-sudo # used to run toggle-cpu-governor
  ]
  ++ nixpkgsDeps;

  # The upower module renders a GTK symbolic battery icon from an icon theme.
  prefix.XDG_DATA_DIRS = "${pkgs.adwaita-icon-theme}/share";

  # waybar.service points at the unwrapped binary; patch it to use the wrapper
  filesToPatch = [ "$out/share/systemd/user/waybar.service" ];
}
