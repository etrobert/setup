old_lock=$1
new_lock=$2

echo "<!-- inputs -->"
echo "| Input | Change |"
echo "| --- | --- |"
jq --raw-output --slurpfile old "$old_lock" '
  def locked: . as $lock
    | $lock.nodes.root.inputs
    | with_entries(select(.value | type == "string"))
    | map_values($lock.nodes[.].locked);
  ($old[0] | locked) as $before
  | locked
  | to_entries[]
  | select($before[.key].narHash != .value.narHash)
  | .key as $name
  | $before[$name].rev as $from
  | .value as $to
  | (if $to.type == "github" then
       "[`\($from[0:7])` → `\($to.rev[0:7])`]"
       + "(https://github.com/\($to.owner)/\($to.repo)"
       + "/compare/\($from)...\($to.rev))"
     # file and tarball inputs have no rev; the content hash is all they carry
     else "`\($before[$name].narHash[7:15])` → `\($to.narHash[7:15])`"
     end) as $change
  | "| \($name) | \($change) |"
' "$new_lock"
