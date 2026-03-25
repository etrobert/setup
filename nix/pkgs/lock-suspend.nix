{ pkgs }:
pkgs.writeShellApplication {
  name = "lock-suspend";
  runtimeInputs = with pkgs; [
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
