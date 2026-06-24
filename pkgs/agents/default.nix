{
  self',
  writeShellApplication,
  coreutils,
  gnugrep,
  jq,
}:
writeShellApplication {
  name = "agents";

  runtimeInputs = [
    self'.packages.claude-code-wrapped # provides `claude`
    coreutils
    gnugrep
    jq
  ];

  inheritPath = false;
  text = ''
    cwd="''${1:-$PWD}"

    # macOS keychain workaround for the background-agents daemon.
    #
    # `claude agents` runs its sessions in a detached daemon. On macOS that
    # daemon leaves the GUI security session and can no longer read the login
    # keychain where the OAuth token lives, so it reports "Not logged in".  The
    # foreground strips CLAUDE_CODE_OAUTH_TOKEN (and the auth-snapshot path) from
    # the daemon's environment when it spawns it, and the snapshot hand-off it is
    # supposed to do instead doesn't fire — so the daemon never authenticates.
    # (Upstream bug; tracked at https://github.com/anthropics/claude-code/issues.)
    #
    # We run here in the attached session, so we *can* read the keychain.  Pull
    # the OAuth token, start a pre-authenticated daemon ourselves (a daemon
    # spawned directly keeps CLAUDE_CODE_OAUTH_TOKEN), and let `claude agents`
    # adopt it — a running daemon is never displaced.  The injected token isn't
    # refreshable, so the daemon is good until the token expires (~the keychain
    # item's expiry); re-running `agents` re-injects a fresh one.
    if [ "$(uname)" = "Darwin" ]; then
      # Service names contain spaces ("Claude Code-credentials-<hash>"), so read
      # them one per line rather than word-splitting.  The hash is derived from
      # CLAUDE_CONFIG_DIR, so there may be several; pick the first unexpired one.
      tok=""
      while IFS= read -r svc; do
        [ -n "$svc" ] || continue
        tok=$(/usr/bin/security find-generic-password -s "$svc" -w 2>/dev/null \
          | jq -r '.claudeAiOauth | select((.expiresAt / 1000) > now) | .accessToken // empty' \
            2>/dev/null) || true
        [ -n "$tok" ] && break
      done < <(/usr/bin/security dump-keychain 2>/dev/null \
        | grep -oE 'Claude Code-credentials-[0-9a-f]+' | sort -u)

      if [ -n "$tok" ]; then
        claude daemon stop --any >/dev/null 2>&1 || true
        CLAUDE_CODE_OAUTH_TOKEN="$tok" CLAUDE_CODE_SUBSCRIPTION_TYPE=max \
          nohup claude daemon run --origin transient >/dev/null 2>&1 &
        sleep 1
      fi
    fi

    # Background agents view scoped to one project: claude agents merges
    # background sessions from every project into one list.  --cwd restricts it
    # to sessions started under a path; default to the current dir, accept an
    # optional path override.
    exec claude agents --cwd "$cwd"
  '';
}
