---
name: google-health
description:
  Read the user's Fitbit Air / personal health data (steps, sleep, heart rate,
  exercise, energy, profile) via the Google Health API. Use whenever the user
  asks to fetch, analyze, summarize, or report on their
  fitness/health/Fitbit/activity/sleep data.
---

# Google Health (Fitbit Air) access

The user's Fitbit Air syncs to their Google account (not the classic Fitbit app,
and not Apple Health yet). Read it on demand via the **Google Health API**
(`health.googleapis.com/v4`) using `curl` directly — there is no wrapper
package.

## Credentials

- OAuth client `client_id`/`client_secret`: agenix secret decrypted to
  `/run/agenix/google-health-oauth-client` (JSON). Available on all workstations
  (requires a `nixos-rebuild switch` after the secret was added).
- **Refresh token**: machine-local, writable file
  `~/.local/share/google-health/refresh-token`. It rotates, so it can't live in
  read-only agenix. It is per-machine — if absent on this host, run the
  re-consent flow below to mint one.

## Fetch data

Access tokens last ~1h; mint a fresh one from the refresh token each time:

```sh
client=/run/agenix/google-health-oauth-client
access=$(curl -s \
  --data-urlencode "client_id=$(jq -r '(.web // .installed).client_id' "$client")" \
  --data-urlencode "client_secret=$(jq -r '(.web // .installed).client_secret' "$client")" \
  --data-urlencode "refresh_token=$(cat ~/.local/share/google-health/refresh-token)" \
  --data-urlencode "grant_type=refresh_token" \
  https://oauth2.googleapis.com/token | jq -r .access_token)

# Profile (age, membership date, stride lengths):
curl -s -H "Authorization: Bearer $access" \
  https://health.googleapis.com/v4/users/me/profile

# Data points for a type:
curl -s -H "Authorization: Bearer $access" \
  'https://health.googleapis.com/v4/users/me/dataTypes/steps/dataPoints'
```

**Verified endpoints:** `users/me/profile` and
`users/me/dataTypes/<type>/dataPoints`, where `<type>` ∈ `steps`, `exercise`,
`sleep`, `heart-rate`, `active-energy-burned`, … Returned points carry
`"platform": "FITBIT"`. Filter by date with a query param, e.g.
`?filter=steps.interval.civil_start_time >= "2026-06-01T00:00:00"`.

## ~Weekly re-consent (when a refresh returns `invalid_grant`)

The OAuth app is in _Testing_ status with restricted scopes, so Google revokes
the refresh token after **7 days**. To re-mint it, ask the user to authorize a
fresh consent URL and paste back the `code`.

1. Build the consent URL (uses the same client_id from the agenix secret):

   ```sh
   client=/run/agenix/google-health-oauth-client
   python3 - "$(jq -r '(.web // .installed).client_id' "$client")" <<'PY'
   import sys, urllib.parse
   scopes = " ".join(
       "https://www.googleapis.com/auth/googlehealth." + s + ".readonly"
       for s in ("activity_and_fitness", "sleep",
                 "health_metrics_and_measurements", "profile"))
   params = dict(client_id=sys.argv[1], redirect_uri="https://www.google.com",
                 response_type="code", scope=scopes,
                 access_type="offline", prompt="consent",
                 include_granted_scopes="true")
   print("https://accounts.google.com/o/oauth2/v2/auth?" + urllib.parse.urlencode(params))
   PY
   ```

2. User opens it, approves (clicking through the "unverified app" warning), and
   pastes the `code` from the `https://www.google.com/?code=…` redirect.

3. Exchange it and overwrite the refresh token (pass the code verbatim;
   `--data-urlencode` handles the `4/0A…` encoding):

   ```sh
   client=/run/agenix/google-health-oauth-client
   refresh=$(curl -s \
     --data-urlencode "code=PASTE_CODE_HERE" \
     --data-urlencode "client_id=$(jq -r '(.web // .installed).client_id' "$client")" \
     --data-urlencode "client_secret=$(jq -r '(.web // .installed).client_secret' "$client")" \
     --data-urlencode "redirect_uri=https://www.google.com" \
     --data-urlencode "grant_type=authorization_code" \
     https://oauth2.googleapis.com/token | jq -r .refresh_token)
   mkdir -p ~/.local/share/google-health && chmod 700 ~/.local/share/google-health
   (umask 077; printf '%s' "$refresh" > ~/.local/share/google-health/refresh-token)
   ```

Moving the app to _Production_ would remove the 7-day limit but requires
Google's paid restricted-scope security review — not worth it for personal use.
