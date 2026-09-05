# Miniflux feed reader, reachable on the tailnet as `feeds/` through tsnsrv and
# syncable from phone apps over its Fever and Google Reader APIs.
#
# No password: tsnsrv identifies the tailnet user on every request and Miniflux
# trusts that header, creating the account on first visit. tsnsrv strips any
# X-Tailscale-* header a client sends before adding its own, and the listener is
# loopback-only, so the only thing that could forge the header is a process on
# tower itself. The Fever and Google Reader endpoints keep their own credentials,
# set per user under Settings > Integrations.
_: {
  flake.nixosModules.miniflux =
    { config, ... }:
    {
      services.miniflux = {
        enable = true;

        config = {
          # Loopback only, for tsnsrv. 8080, the upstream default, is taken by
          # the lafraise dev backend.
          LISTEN_ADDR = "127.0.0.1:8085";

          # Absolute links (feed icons, the Fever and Google Reader endpoints
          # handed to phone apps) are built from this, not the request host.
          BASE_URL = "http://feeds";

          AUTH_PROXY_HEADER = "X-Tailscale-User-LoginName-Localpart";
          AUTH_PROXY_USER_CREATION = 1;

          # Miniflux refuses to start with AUTH_PROXY_HEADER unless the header is
          # only honoured from named networks. tsnsrv dials from loopback.
          TRUSTED_REVERSE_PROXY_NETWORKS = "127.0.0.1/32";

          # The upstream module defaults this on and then demands an
          # adminCredentialsFile; the proxy-created user is all there is.
          CREATE_ADMIN = false;

          # Split-horizon DNS puts every etiennerobert.com name, and ntfy on
          # tower, on the LAN, which Miniflux's SSRF guard refuses by default.
          # Only this user adds feeds, so there is nothing for it to protect.
          FETCHER_ALLOW_PRIVATE_NETWORKS = 1;
          INTEGRATION_ALLOW_PRIVATE_NETWORKS = 1;
        };
      };

      services.tsnsrv.services.feeds.toURL = "http://${config.services.miniflux.config.LISTEN_ADDR}";
    };
}
