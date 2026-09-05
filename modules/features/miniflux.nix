# Miniflux feed reader, reachable on the tailnet as `feeds/` through tsnsrv and
# syncable from phone apps over its Fever and Google Reader APIs.
#
# No password: tsnsrv identifies the tailnet user on every request and Miniflux
# trusts that header, creating the account on first visit. tsnsrv strips any
# X-Tailscale-* header a client sends before adding its own, and the listener is
# loopback-only, so the only thing that could forge the header is a process on
# tower itself. The Fever and Google Reader endpoints keep their own credentials,
# set per user under Settings > Integrations.
#
# New articles are announced over ntfy as one digest per hour (daytime only),
# read straight from the database as Postgres' superuser — the same way the
# upstream module's own setup unit talks to it — so no API key is needed.
{ self, ... }:
{
  flake.nixosModules.miniflux =
    { config, pkgs, ... }:
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
        };
      };

      services.tsnsrv.services.feeds.toURL = "http://${config.services.miniflux.config.LISTEN_ADDR}";

      systemd.services.miniflux-notify = {
        description = "Announce new unread Miniflux entries over ntfy";

        requires = [ "postgresql.target" ];
        after = [
          "postgresql.target"
          "miniflux.service"
        ];

        path = [
          config.services.postgresql.package
          self.packages.${pkgs.stdenv.hostPlatform.system}.ntfy-wrapped
        ];

        # The state is the highest entry id already announced. Only entries
        # above it that are still unread count, so anything read before the
        # digest fires is not announced. The first run seeds the mark without
        # notifying, or the whole backlog would arrive as one message.
        script = /* bash */ ''
          set -u -o pipefail

          state=$STATE_DIRECTORY/last-id

          query() {
            psql miniflux --quiet --tuples-only --no-align --command "$1"
          }

          if ! last=$(cat "$state" 2>/dev/null) || ! [[ $last =~ ^[0-9]+$ ]]; then
            query "SELECT coalesce(max(id), 0) FROM entries" > "$state"
            echo "seeded last-id with $(cat "$state")"
            exit 0
          fi

          latest=$(query "SELECT coalesce(max(id), $last) FROM entries")
          count=$(query "SELECT count(*) FROM entries WHERE status = 'unread' AND id > $last")

          if [ "$count" -eq 0 ]; then
            echo "$latest" > "$state"
            echo "nothing new since entry $last"
            exit 0
          fi

          if [ "$count" -eq 1 ]; then
            title="1 new article"
          else
            title="$count new articles"
          fi

          # Newest first, capped so the notification stays a glance.
          {
            query "SELECT title FROM entries WHERE status = 'unread' AND id > $last ORDER BY id DESC LIMIT 5"
            if [ "$count" -gt 5 ]; then
              echo "… and $((count - 5)) more"
            fi
          } | ntfy publish --quiet --title "$title" --click http://feeds/unread

          # Advanced only after a delivered notification, so a failed one is
          # retried with the same entries next time.
          echo "$latest" > "$state"
          echo "announced $count entries above $last"
        '';

        serviceConfig = {
          Type = "oneshot";
          User = config.services.postgresql.superUser;
          StateDirectory = "miniflux-notify";
        };
      };

      systemd.timers.miniflux-notify = {
        description = "Schedule the hourly Miniflux digest";
        wantedBy = [ "timers.target" ];

        # Feeds refresh spread across each hour (POLLING_FREQUENCY), so a digest
        # per hour keeps up. Quiet overnight; the morning run carries the
        # night's entries.
        timerConfig = {
          OnCalendar = "*-*-* 08..22:05:00";
          Persistent = true;
        };
      };
    };
}
