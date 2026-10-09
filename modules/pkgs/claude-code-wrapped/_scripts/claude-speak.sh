summary=$(jq --raw-output '.last_assistant_message | capture("<!-- TTS: (?<text>[\\s\\S]*?) -->").text')
[[ -z "$summary" ]] && exit 0

# Exit 7 (connection refused): this host runs no kokoro-speak.
curl --silent --show-error --data-binary "$summary" http://localhost:8880/say || [[ $? == 7 ]]
