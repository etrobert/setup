{
  lib,
  writeShellApplication,
  coreutils,
  systemd,
}:
writeShellApplication {
  name = "lock-suspend";
  meta.platforms = lib.platforms.linux;
  runtimeInputs = [
    coreutils # sleep
    systemd
  ];
  inheritPath = false;
  text = ''
    loginctl lock-session
    sleep 1
    systemctl suspend
  '';
}
