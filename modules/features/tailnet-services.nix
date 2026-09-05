# Give local services their own MagicDNS names, so Home Assistant is `home/`
# rather than `tower:8123`.
#
# tsnsrv joins each service to the tailnet as its own device via tsnet, then
# reverse-proxies to a local port. The names resolve on the tailnet only, at
# home and away — nothing is published to the LAN or the WAN.
#
# Plaintext on :80 is deliberate. No public CA issues certificates for
# single-label names, so HTTPS would only ever be valid on the full
# `<name>.tailcab4c0.ts.net` form; serving :80 is what makes the bare name work,
# the same way `tower:8123` is reached today. Traffic is inside WireGuard either
# way.
#
# This module owns tsnsrv itself and its defaults. Each name is declared by the
# feature it belongs to, next to the listener it points at
# (`services.tsnsrv.services.<name>`). `plaintext` has no defaults entry, so
# every service sets it.
{ inputs, ... }:
{
  flake.nixosModules.tailnetServices =
    { config, ... }:
    {
      imports = [ inputs.tsnsrv.nixosModules.default ];

      services.tsnsrv = {
        enable = true;

        # systemd reads the credential as root before dropping to the unit's
        # DynamicUser, so the secret needs no ownership of its own.
        defaults = {
          authKeyPath = config.age.secrets.tailscale-authkey.path;
          listenAddr = ":80";
        };
      };
    };
}
