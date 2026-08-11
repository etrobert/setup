# Wraps gh with etrobert-bot's token, read from agenix at launch, so the CI
# workflows on tower's runners get an authenticated gh without any Actions
# secret plumbing. Same treatment as GITHUB_TOKEN in claude-code-wrapped:
# `$(<file)` builtin so the read needs no `cat`, and a bare assignment so
# `set -e` aborts on an unreadable secret instead of baking in an empty token.
{
  gh,
  wrapPackage,
}:
wrapPackage {
  package = gh;
  inheritPath = true;

  run = [
    ''GITHUB_TOKEN="$(< /run/agenix/github-bot-token)"''
    "export GITHUB_TOKEN"
  ];
}
