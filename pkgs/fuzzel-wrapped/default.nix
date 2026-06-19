{ wrapPackage, fuzzel }:
wrapPackage {
  package = fuzzel;
  # Niri runs as a systemd service with a minimal PATH. Fuzzel inherits that
  # PATH and uses it to exec apps from .desktop Exec= lines. Prefix the
  # system packages path so those apps are findable.  makeBinPath appends /bin,
  # so pass the prefix without it.
  runtimeInputs = [ "/run/current-system/sw" ];
  inheritPath = true;
}
