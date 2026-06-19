{
  fuzzel,
  wrapPackage,
}:
wrapPackage {
  package = fuzzel;
  # Niri runs as a systemd service with a minimal PATH.  Fuzzel inherits that
  # PATH and uses it to exec apps from .desktop Exec= lines.  Prefix the
  # system packages path so those apps are findable.
  extraWrapArgs = [
    "--prefix"
    "PATH"
    ":"
    "/run/current-system/sw/bin"
  ];
}
