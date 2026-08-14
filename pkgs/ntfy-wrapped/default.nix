# Wraps the ntfy CLI with NTFY_TOPIC pre-set to our self-hosted endpoint so
# `ntfy publish "msg"` reaches it without naming the server or topic.
# Port and topic mirror modules/features/ntfy.nix.
#
# Tower's Tailscale IP, not the `tower` hostname: pi resolves through its own
# dnsmasq (no-resolv, no MagicDNS), so `tower` does not resolve there and every
# ntfy-failure@ alert died with "lookup tower: no such host". The LAN address is
# no help either — ntfy's port is opened on tailscale0 only.
{
  ntfy-sh,
  wrapPackage,
}:
wrapPackage {
  package = ntfy-sh;
  # --set-default, so an NTFY_TOPIC in the environment still wins for ad-hoc
  # overrides.
  setDefaults.NTFY_TOPIC = "http://100.103.91.42:2586/home";
}
