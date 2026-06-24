# `send-file <path>` — publish a file to the home ntfy topic as an attachment,
# delivered to the phone and desktops. Thin wrapper over `ntfy publish --file`
# using ntfy-wrapped (which bakes in NTFY_TOPIC).
{
  writeShellApplication,
  ntfy-wrapped,
}:
writeShellApplication {
  name = "send-file";
  runtimeInputs = [ ntfy-wrapped ];
  inheritPath = false;
  text = builtins.readFile ./send-file.sh;
}
