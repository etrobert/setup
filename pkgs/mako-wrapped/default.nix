{
  mako,
  writeText,
  wrapPackage,
}:
let
  config = writeText "config" /* ini */ ''
    font=monospace 12
    margin=20
    default-timeout=5000
    border-radius=6
    background-color=#24273a
    border-color=#cdd6f4

    # Firefox/Zen request timeout=0 (never expire) for notifications like Google Calendar.
    # Override this to use our default-timeout instead.
    [app-name=Firefox]
    ignore-timeout=1

    [app-name="Zen"]
    ignore-timeout=1
  '';
in
wrapPackage {
  package = mako;
  flags = [ "--config ${config}" ];
  # mako ships a dbus service and a systemd user service that both reference the
  # unwrapped binary; patch them so activation uses the wrapper instead.
  filesToPatch = [
    "$out/share/dbus-1/services/*.service"
    "$out/share/systemd/user/*.service"
  ];
}
