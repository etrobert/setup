{
  writeShellApplication,
  niri,
  awww,
}:
writeShellApplication {
  name = "awww-restore-on-hotplug";
  runtimeInputs = [
    niri
    awww
  ];
  text = ''
    niri msg --json event-stream | while read -r line; do
      case "$line" in *'"ConfigLoaded"'*) ;; *) continue ;; esac
      sleep 0.5
      awww restore
    done
  '';
}
