# Otherwise a failed mount enters emergency mode, which stops sshd and the
# network on a host nobody sits in front of.
_: {
  flake.nixosModules.no-emergency-mode = {
    systemd.enableEmergencyMode = false;
  };
}
