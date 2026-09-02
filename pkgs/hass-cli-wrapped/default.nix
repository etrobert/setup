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
        # `$(<file)` builtin so the read doesn't need `cat` on the caller's PATH
        # (`run` snippets execute before the wrapper's own PATH line), and a bare
        # assignment so `set -e` aborts on an unreadable secret — `export VAR=$(…)`
        # returns the export's status, masking the failure and baking in an empty token.
        run = [
          ''HASS_TOKEN="''${HASS_TOKEN:-$(< /run/agenix/hass-token)}"''
          "export HASS_TOKEN"
        ];
      };
    };
}
