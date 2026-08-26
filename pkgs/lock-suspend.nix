{
  writeShellApplication,
  coreutils,
  systemd,
}:
writeShellApplication {
  name = "lock-suspend";
  runtimeInputs = [
    coreutils # sleep
    systemd
  ];
  inheritPath = false;
  text = /* bash */ ''
    loginctl lock-session
    sleep 1
    systemctl suspend
  '';
}
