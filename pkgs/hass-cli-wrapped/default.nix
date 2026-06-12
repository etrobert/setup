# Wraps the Home Assistant CLI with HASS_SERVER pre-set to our instance and
# HASS_TOKEN sourced from the agenix-managed long-lived token, so `hass-cli`
# works in an interactive shell with no manual config. An existing HASS_SERVER
# or HASS_TOKEN in the environment wins, so ad-hoc overrides still work.
# Token wiring mirrors pkgs/claude-code-wrapped/default.nix; the secret is
# declared in modules/workstation.nix and secrets/secrets.nix.
{
  makeWrapper,
  home-assistant-cli,
  runCommandLocal,
}:
runCommandLocal "hass-cli-wrapped"
  {
    nativeBuildInputs = [ makeWrapper ];
    meta.mainProgram = "hass-cli";
  }
  ''
    makeWrapper ${home-assistant-cli}/bin/hass-cli $out/bin/hass-cli \
      --set-default HASS_SERVER http://tower:8123 \
      --run 'export HASS_TOKEN="''${HASS_TOKEN:-$(cat /run/agenix/hass-token 2>/dev/null || true)}"'
  ''
