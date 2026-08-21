# STATE_DIRECTORY and DEPLOY_URL come from the nixos-upgrade unit; no defaults,
# so set -u fails rather than silently gating on the wrong repo or directory.
last_rev="$STATE_DIRECTORY/last-attempted-rev"
pending_rev="$STATE_DIRECTORY/pending-rev"

case "$1" in
  check)
    rev=$(git ls-remote "$DEPLOY_URL" deploy | cut --fields=1)
    if [ -z "$rev" ]; then
      echo "could not resolve deploy ref; skipping" >&2
      exit 1
    fi
    if [ -f "$last_rev" ] && [ "$rev" = "$(cat "$last_rev")" ]; then
      echo "deploy $rev already attempted; skipping"
      exit 1
    fi
    printf '%s\n' "$rev" > "$pending_rev"
    echo "deploy $rev differs from last attempt; upgrading"
    ;;
  record)
    if [ -f "$pending_rev" ]; then
      mv "$pending_rev" "$last_rev"
    fi
    ;;
  *)
    echo "usage: deploy-gate {check|record}" >&2
    exit 2
    ;;
esac
