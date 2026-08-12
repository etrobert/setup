# Searches the Immich library from the command line: OCR text (wifi passwords,
# signs, receipts) and CLIP semantic search, both of which the upstream
# immich-cli does not cover. Key wiring mirrors pkgs/hass-cli-wrapped; the
# secret is declared in modules/profiles/workstation.nix and secrets/secrets.nix.
{
  writeShellApplication,
  coreutils,
  curl,
  jq,
}:
writeShellApplication {
  name = "immich-search";

  runtimeInputs = [
    coreutils
    curl
    jq
  ];

  inheritPath = false;
  text = builtins.readFile ./immich-search.sh;
}
