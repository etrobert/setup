name=$1
body_file=$2

content=$(cat)

# Body minus any previous section, with CRs and trailing blanks trimmed so
# repeated runs converge instead of accumulating separators.
awk -v start="<!-- $name -->" -v end="<!-- /$name -->" '
  { sub(/\r$/, "") }
  $0 == start { skip = 1; next }
  $0 == end { skip = 0; next }
  skip { next }
  { kept[n++] = $0 }
  END {
    while (n > 0 && kept[n - 1] ~ /^[[:space:]]*$/) n--
    for (i = 0; i < n; i++) print kept[i]
    if (n > 0) print ""
  }
' "$body_file"

printf '%s\n' "<!-- $name -->" "$content" "<!-- /$name -->"
