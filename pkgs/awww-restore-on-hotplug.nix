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
      case "$line" in *'"WorkspacesChanged"'*) ;; *) continue ;; esac
      cur=$(niri msg --json outputs | jq --raw-output 'keys[]' | sort | paste --serial --delimiters=,)
      [ "$cur" = "$prev" ] && continue
      prev="$cur"
      sleep 0.5
      awww restore
    done
  '';
}
