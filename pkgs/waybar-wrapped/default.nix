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
    sudo # used to run toggle-cpu-governor
  ];
in
wrapPackage {
  package = pkgs.waybar;
  flags = [
    "--config ${config}"
    "--style ${style}"
  ];
  runtimeInputs = nixpkgsDeps;
  # waybar.service points at the unwrapped binary; patch it to use the wrapper
  filesToPatch = [ "$out/share/systemd/user/waybar.service" ];
}
