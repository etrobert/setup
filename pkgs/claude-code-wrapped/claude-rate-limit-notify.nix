{
  coreutils,
  gnugrep,
  jq,
  lib,
  libnotify,
  stdenv,
  systemd,
  writeShellApplication,
}:
let
  # notify() and schedule_reset() are the only platform-specific primitives;
  # the shared logic lives in claude-rate-limit-notify.sh.
  linuxPrimitives = ''
    notify() { notify-send "$1" "$2"; }
    schedule_reset() {
      systemd-run --user --on-active="$1s" --unit=claude-rate-limit-reset \
        notify-send "Claude" "Usage window has reset — you're good to go"
    }
  '';
  darwinPrimitives = ''
    notify() {
      # Pass title/body as argv so quotes/backslashes/newlines can't break or
      # inject into the AppleScript.
      /usr/bin/osascript \
        -e 'on run argv' \
        -e 'display notification (item 2 of argv) with title (item 1 of argv)' \
        -e 'end run' \
        "$1" "$2"
    }
    schedule_reset() {
      # No systemd on macOS; detach a sleep that survives the parent exiting.
      ( trap "" HUP; sleep "$1"; notify "Claude" "Usage window has reset — you're good to go" ) >/dev/null 2>&1 &
    }
  '';
in
writeShellApplication {
  name = "claude-rate-limit-notify";
  runtimeInputs = [
    coreutils
    gnugrep
    jq
  ]
  ++ lib.optionals stdenv.isLinux [
    libnotify
    systemd
  ];
  inheritPath = false;
  text =
    (if stdenv.isDarwin then darwinPrimitives else linuxPrimitives)
    + builtins.readFile ./claude-rate-limit-notify.sh;
}
