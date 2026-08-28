{
  self',
  writeShellApplication,
}:
writeShellApplication {
  name = "agents";
  runtimeInputs = [ self'.packages.claude-code-wrapped ]; # provides `claude`
  inheritPath = true;
  text = ''
    # Background agents view scoped to one project: claude agents merges
    # background sessions from every project into one list.  --cwd restricts it
    # to sessions started under the current directory.
    claude agents --cwd "$PWD"
  '';
}
