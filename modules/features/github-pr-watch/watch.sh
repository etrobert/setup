# Repos I own, and the day job's org, which has its own channels.
exclude_owners=(etrobert lafraise-pro)

# Marking delivered threads read keeps the cursor on GitHub's side; the
# window bounds how many pages of excluded threads a poll re-reads.
threads=$(gh api --paginate \
  "notifications?participating=true&since=$(date --utc --date='30 days ago' +%FT%TZ)" |
  jq --raw-output --args '
    .[]
    | select(.subject.type == "PullRequest")
    | select(.repository.owner.login | IN($ARGS.positional[]) | not)
    | [.id, .repository.full_name, (.subject.url | split("/") | last), .subject.title,
       .subject.url, (.subject.latest_comment_url // .subject.url), .reason, .last_read_at]
    | @tsv' "${exclude_owners[@]}")

failed=0

while IFS=$'\t' read -r id repo number title url latest reason last_read; do
  [ -n "$id" ] || continue

  # A permanent 4xx here (access lost) must not starve the other threads.
  if ! pr=$(gh api "$url"); then
    echo "$repo#$number: fetch failed" >&2
    failed=1
    continue
  fi

  # A merge or close since the thread was last read outranks the comment a
  # bot typically posts right after it.
  kind=$(jq --raw-output --arg since "$last_read" --arg latest "$latest" --arg reason "$reason" '
    if .merged and .merged_at > $since then "merged by \(.merged_by.login)"
    elif .state == "closed" and .closed_at > $since then "closed"
    elif $latest | test("/issues/comments/") then "comment"
    elif $reason == "review_requested" then "review requested"
    else "activity" end' <<<"$pr")

  click=https://github.com/$repo/pull/$number
  [ "$kind" != comment ] || click="$click#issuecomment-${latest##*/}"

  echo "$repo#$number: $kind"
  ntfy publish --quiet --title "$repo#$number $kind" --click "$click" --message "$title"
  gh api --method PATCH "notifications/threads/$id"
done <<<"$threads"

exit "$failed"
