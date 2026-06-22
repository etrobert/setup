{
  self',
  writeShellApplication,
}:
writeShellApplication {
  name = "agents";
  runtimeInputs = [ self'.packages.claude-code-wrapped ]; # provides `claude`
  inheritPath = false;
  text = ''
    # Background agents view scoped to one project: claude agents merges
    # background sessions from every project into one list.  --cwd restricts it
    # to sessions started under a path; default to the current dir, accept an
    # optional path override.
    claude agents --cwd "''${1:-$PWD}"
  '';
}
