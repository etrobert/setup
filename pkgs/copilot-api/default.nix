{
  writeShellApplication,
  nodejs,
}:
# Reverse-engineered proxy that exposes GitHub Copilot as an OpenAI/Anthropic
# compatible server (https://github.com/ericc-ch/copilot-api). Fetched from npm
# at runtime via npx; bump the pinned version below to upgrade.
writeShellApplication {
  name = "copilot-api";
  runtimeInputs = [ nodejs ];
  inheritPath = false;
  text = ''
    exec npx -y copilot-api@0.7.0 "$@"
  '';
}
