#!/usr/bin/env bash
# Send a file to the home ntfy topic (phone + desktops) as an attachment.
# Takes exactly the path. Usage: send-file <path>

if [ "$#" -ne 1 ]; then
  echo "usage: send-file <path>" >&2
  exit 1
fi

# NTFY_TOPIC is baked into ntfy-wrapped, so topic/server need not be named here.
# No title/message: the server fills the body with "You received a file: <name>".
# ntfy itself errors clearly on a missing path or a directory.
ntfy publish --file "$1"
