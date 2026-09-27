---
name: pr-screenshot
description:
  Capture a screenshot of a user-visible change (UI, status bar, terminal
  styling, CLI output) and attach it to a GitHub pull request description. Use
  whenever a PR needs a screenshot, or when rendering a terminal UI headlessly.
---

# PR screenshot

## Terminal UI

When rendering a terminal-UI screenshot headlessly (xterm under Xvfb), load the
terminal theme's 16-color ANSI palette into xterm
(`-xrm 'xterm*color4: #8aadf4' …`) — otherwise palette references like
`colour4`/`colour0` render as harsh xterm defaults instead of the real theme
colors.

## Attach

Upload the way the web textarea does — the endpoint behind paste-into-comment
takes a `gh` token:

```bash
curl --request POST --header "Authorization: Bearer $(gh auth token)" \
  --data-binary @shot.png \
  "https://uploads.github.com/user-attachments/assets?name=shot.png&content_type=image/png&repository_id=$(gh api repos/OWNER/REPO --jq .id)"
```

Put the returned `github.com/user-attachments/assets/<uuid>` in the PR body. It
404s on a direct fetch — GitHub mints a short-lived signed URL at render time,
for anonymous viewers too — so don't take that 404 as a failed upload. The
endpoint is undocumented and `gh` has no native support. It rejects Actions'
`GITHUB_TOKEN` (404), so CI needs a PAT.

scp to `tower:/tank/public/` (served at `files.etiennerobert.com/`) is the
fallback when a directly-fetchable URL is needed. That directory is public and
browsable, so keep private content out of anything uploaded there.
