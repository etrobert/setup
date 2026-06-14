{
  writeShellApplication,
  niri,
  awww,
  jq,
}:
writeShellApplication {
  name = "awww-restore-on-hotplug";
  runtimeInputs = [
    niri
    awww
    jq
  ];
  text = ''
    prev=$(niri msg --json outputs | jq --raw-output 'keys[]' | sort | paste --serial --delimiters=,)
    niri msg --json event-stream | while read -r line; do
      case "$line" in
        *'"ConfigLoaded"'*)
          # Fires on monitor power cycle and physical hotplug
          sleep 0.5
          awww restore
          ;;
        *'"WorkspacesChanged"'*)
          # Fires on physical cable disconnect/reconnect (output set changes)
          cur=$(niri msg --json outputs | jq --raw-output 'keys[]' | sort | paste --serial --delimiters=,)
          [ "$cur" = "$prev" ] && continue
          prev="$cur"
          sleep 0.5
          awww restore
          ;;
      esac
    done
  '';
}
