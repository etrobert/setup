{ writeShellApplication, jq }:
writeShellApplication {
  name = "claude-restart-daemon";
  runtimeInputs = [ jq ];
  inheritPath = false;
  text = ''
    status_file="$HOME/setup/pkgs/claude-code-wrapped/config/daemon.status.json"

    if [ ! -f "$status_file" ]; then
      echo "No daemon status file found at $status_file"
      exit 1
    fi

    pid=$(jq -r '.supervisorPid' "$status_file")

    if [ -z "$pid" ] || [ "$pid" = "null" ]; then
      echo "No supervisorPid found in $status_file"
      exit 1
    fi

    if kill "$pid" 2>/dev/null; then
      echo "Killed Claude daemon (PID $pid)"
    else
      echo "Daemon (PID $pid) was already gone"
    fi
  '';
}
