# Replace a `<!-- name -->`…`<!-- /name -->` section of a PR body (file
# argument) with new content (stdin), appending it if absent.
{
  writeShellApplication,
  gawk,
  coreutils,
}:
writeShellApplication {
  name = "pr-body-section";

  runtimeInputs = [
    gawk
    coreutils
  ];

  inheritPath = false;
  text = builtins.readFile ./pr-body-section.sh;
}
