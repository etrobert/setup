cd "$STATE_DIRECTORY"
mkdir --parents issues public

day=$(date --utc +%F)
issue=$STATE_DIRECTORY/issues/$day.html

claude --print "$(cat "$NEWSLETTER_PROMPT")

Today is $day. Write the issue to $issue."

if [ ! -s "$issue" ]; then
  echo "claude did not write $issue" >&2
  exit 1
fi

escape() {
  sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g' "$1"
}

# Bounded so the feed does not grow forever; Miniflux keeps older entries.
mapfile -t recent < <(printf '%s\n' issues/*.html | sort --reverse | head --lines 30)

{
  cat <<EOF
<?xml version="1.0" encoding="utf-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
<title>Newsletter</title>
<id>urn:newsletter</id>
<updated>$(date --utc +%FT%TZ)</updated>
EOF
  for file in "${recent[@]}"; do
    name=$(basename "$file" .html)
    cat <<EOF
<entry>
<title>Newsletter $name</title>
<id>urn:newsletter:$name</id>
<updated>${name}T00:00:00Z</updated>
<content type="html">$(escape "$file")</content>
</entry>
EOF
  done
  echo '</feed>'
} >public/feed.xml.tmp

mv public/feed.xml.tmp public/feed.xml
