# Ghostty's Ctrl+Click includes a trailing . , : ? or ) in the link
# \x27: a single quote, which this shell string cannot hold
jq '{
  hookSpecificOutput: {
    hookEventName: "MessageDisplay",
    displayContent: (.delta | gsub(
      "(?<url>https?://[^\\s<>\"\\x27`]*[^\\s<>\"\\x27`.,:?)]>?)(?<tail>[.,:?)]+)(?![^\\s<>\"\\x27`])";
      "\(.url) \(.tail)"
    ))
  }
}'
