# Wraps the Home Assistant CLI with HASS_SERVER pre-set to our instance and
# HASS_TOKEN sourced from the agenix-managed long-lived token, so `hass-cli`
# works in an interactive shell with no manual config. An existing HASS_SERVER
# or HASS_TOKEN in the environment wins, so ad-hoc overrides still work.
# Token wiring mirrors pkgs/claude-code-wrapped/default.nix; the secret is
# declared in modules/workstation.nix and secrets/secrets.nix.
{
  home-assistant-cli,
  wrapPackage,
}:
wrapPackage {
  package = home-assistant-cli;
  # tower's Tailscale IP rather than the `tower` hostname: hass-cli is built on
  # aiohttp, whose closure includes aiodns, so aiohttp resolves names via c-ares
  # instead of getaddrinfo. c-ares reads /etc/resolv.conf directly and ignores
  # macOS scoped DNS / Tailscale MagicDNS, so `tower` fails to resolve on aaron
  # (ClientConnectorDNSError). An IP sidesteps name resolution on every OS.
  setDefaults.HASS_SERVER = "http://100.103.91.42:8123";
  extraWrapArgs = [
    "--run"
    "export HASS_TOKEN=\"\${HASS_TOKEN:-$(cat /run/agenix/hass-token)}\""
  ];
}
