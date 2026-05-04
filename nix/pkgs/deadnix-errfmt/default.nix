{
  writeShellApplication,
  deadnix,
  jq,
}:
writeShellApplication {
  name = "deadnix-errfmt";
  runtimeInputs = [
    deadnix
    jq
  ];
  inheritPath = false;
  text = ''
    deadnix --output-format json "$@" | \
      jq -r '.file as $f | .results[] | $f + ">" + (.line|tostring) + ":" + (.column|tostring) + ":W:0:" + .message'
  '';
}
