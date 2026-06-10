#!/usr/bin/env bash

set -euo pipefail

NO_EDIT_GIT_PARAM="--edit"
case "${1:-}" in
--no-edit | -n) NO_EDIT_GIT_PARAM= ;;
"") ;;
*)
  echo "Error: Unknown parameter '$1'. Use --no-edit or -n to skip editor." >&2
  exit 1
  ;;
esac

OLLAMA_URL="${OLLAMA_URL:-http://localhost:11434}"
OLLAMA_MODEL="${OLLAMA_MSG_MODEL:-qwen3:8b}"

if ! DIFF=$(git diff --cached -- ':!/package-lock.json' ':!/pnpm-lock.yaml' ':!/yarn.lock' 2>/dev/null); then
  echo "Error: Unable to get staged changes."
  exit 1
fi

if [ -z "$DIFF" ]; then
  echo "No staged changes to commit."
  exit 0
fi

RECENT_COMMITS=$(git log --pretty=format:'%s' --max-count=5)

SYSTEM_PROMPT="You generate git commit messages following the Conventional Commits specification.

Format: type(scope): description
Types: feat, fix, refactor, chore, docs, test, style, perf, ci, build
- scope: infer from the affected package or module (e.g. neovim, ntfy, aaron, home-assistant)
- description: imperative mood, lowercase, no trailing period
- total subject line must be 72 characters or fewer

Output only the commit message subject line, nothing else."

USER_PROMPT="Recent commit messages for style reference:

$RECENT_COMMITS

Write a clear commit message for this diff:

$DIFF"

REQUEST_BODY=$(jq --null-input --arg user_prompt "$USER_PROMPT" --arg system_prompt "$SYSTEM_PROMPT" --arg model "$OLLAMA_MODEL" '{
  "model": $model,
  "messages": [
    {
      "role": "system",
      "content": $system_prompt
    },
    {
      "role": "user",
      "content": $user_prompt
    }
  ],
  "stream": false,
  "think": false
}')

RESPONSE=$(curl -s -w "\n%{http_code}" "$OLLAMA_URL/api/chat" \
  -H "Content-Type: application/json" \
  -d "$REQUEST_BODY")

HTTP_CODE=$(echo "$RESPONSE" | tail -n 1)
RESPONSE_BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -ne 200 ]; then
  echo "Error: Ollama returned HTTP $HTTP_CODE
$RESPONSE_BODY"
  exit 1
fi

MESSAGE=$(echo "$RESPONSE_BODY" | jq -r '.message.content')

if [ -z "$MESSAGE" ]; then
  echo "No commit message generated."
  exit 1
fi

echo "$MESSAGE" | git commit -F - $NO_EDIT_GIT_PARAM
