# SessionStart hook: tell Claude which machine the session is running on, so it
# does not ssh/scp into the host it is already on. The wrapped config is baked
# identically into every machine's store path, so this runtime signal is the
# only host-specific context Claude gets.
#
# Output format per https://code.claude.com/docs/en/hooks (SessionStart).

context="You are running on host: $(uname --nodename)"

jq --null-input --compact-output --arg context "$context" '{
  hookSpecificOutput: {
    hookEventName: "SessionStart",
    additionalContext: $context
  }
}'
