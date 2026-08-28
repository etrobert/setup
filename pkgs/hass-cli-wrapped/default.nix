_: {
  perSystem =
    { pkgs, ... }:
    {
      packages.hass-cli-wrapped = pkgs.wrapPackage {
        package = pkgs.home-assistant-cli;
        # tower's Tailscale IP rather than the `tower` hostname: hass-cli is built on
        # aiohttp, whose closure includes aiodns, so aiohttp resolves names via c-ares
        # instead of getaddrinfo. c-ares reads /etc/resolv.conf directly and ignores
        # macOS scoped DNS / Tailscale MagicDNS, so `tower` fails to resolve on aaron
        # (ClientConnectorDNSError). An IP sidesteps name resolution on every OS.
        # --set-default so an existing HASS_SERVER still wins.
        setDefaults.HASS_SERVER = "http://100.103.91.42:8123";
        # Read the long-lived token at runtime, unless HASS_TOKEN is already set.
        run = [ ''export HASS_TOKEN="''${HASS_TOKEN:-$(cat /run/agenix/hass-token)}"'' ];
      };
    };
}
