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
    sudo # used to run toggle-cpu-governor
  ];
in
wrapPackage {
  package = pkgs.waybar;
  flags = [
    "--config ${config}"
    "--style ${style}"
  ];
  runtimeInputs = [ self'.packages.get-weather ] ++ nixpkgsDeps;

  # The upower module draws a GTK symbolic battery icon looked up via
  # XDG_DATA_DIRS; make the icon theme available without clobbering the session's.
  run = [
    "export XDG_DATA_DIRS=${pkgs.adwaita-icon-theme}/share\${XDG_DATA_DIRS:+:$XDG_DATA_DIRS}"
  ];

  # waybar.service points at the unwrapped binary; patch it to use the wrapper
  filesToPatch = [ "$out/share/systemd/user/waybar.service" ];
}
