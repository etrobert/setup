# Claude keys a worktree's trust on the main checkout, which a bare repo lacks,
# so every new worktree asks again. Stand the bare repo in for the main checkout.

[ "$(git config --get core.bare)" = true ] || exit 0

bare=$(git rev-parse --path-format=absolute --git-common-dir)
worktree=$(git rev-parse --show-toplevel)
config="$CLAUDE_CONFIG_DIR/.claude.json"

[ -f "$config" ] || exit 0

jq --exit-status --arg bare "$bare" --arg worktree "$worktree" \
  '.projects[$bare].hasTrustDialogAccepted == true and .projects[$worktree].hasTrustDialogAccepted != true' \
  "$config" >/dev/null || exit 0

# Same directory, so mv is an atomic rename.
tmp=$(mktemp --tmpdir="$CLAUDE_CONFIG_DIR")
jq --arg worktree "$worktree" '.projects[$worktree].hasTrustDialogAccepted = true' "$config" >"$tmp"
mv "$tmp" "$config"
