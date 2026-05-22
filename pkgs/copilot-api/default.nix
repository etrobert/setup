{
  writeShellApplication,
  nodejs,
  bash,
}:
# Reverse-engineered proxy that exposes GitHub Copilot as an OpenAI/Anthropic
# compatible server (https://github.com/ericc-ch/copilot-api). Fetched from npm
# at runtime via npx; bump the pinned version below to upgrade.
#
# bash is required because npm/npx spawn `sh` at runtime; with inheritPath = false
# it must be on PATH explicitly, otherwise the proxy dies with "spawn sh ENOENT"
# under the minimal systemd environment.
writeShellApplication {
  name = "copilot-api";
  runtimeInputs = [
    nodejs
    bash
  ];
  inheritPath = false;
  text = ''
    exec npx -y copilot-api@0.7.0 "$@"
  '';
}
