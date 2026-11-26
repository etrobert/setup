let
  inherit (import ./secrets/host-keys.nix)
    tower
    leod
    aaron
    pi
    daddy
    peira
    ;

  allLinux = [
    tower
    leod
    pi
    peira
  ];
  allLinuxWorkstations = [
    tower
    leod
  ];
  allWorkstations = [
    tower
    leod
    aaron
  ];
  allMachines = allLinux ++ [ aaron ];
in
{
  "secrets/openai-api-key.age".publicKeys = allWorkstations;
  "secrets/gemini-api-key.age".publicKeys = allWorkstations;
  "secrets/wifi-soft.age".publicKeys = allLinuxWorkstations;
  "secrets/wifi-iphone-de-zeus.age".publicKeys = allLinuxWorkstations;
  "secrets/wifi-vinni.age".publicKeys = allLinuxWorkstations;
  "secrets/tailscale-authkey.age".publicKeys = allMachines;
  "secrets/apple-pimsync-password.age".publicKeys = allLinuxWorkstations;
  "secrets/soft-password.age".publicKeys = allLinux;
  "secrets/ddclient-password-etiennerobert-com.age".publicKeys = [ tower ];
  "secrets/umami-app-secret.age".publicKeys = [ daddy ];
  "secrets/nix-access-tokens.age".publicKeys = allWorkstations;
  "secrets/github-runner-token.age".publicKeys = allWorkstations;
  # Fine-grained tokens carry one resource owner, so lafraise-pro/app cannot
  # share the one above. Unused since the runner moved off tower; kept in case.
  "secrets/lafraise-runner-token.age".publicKeys = [ tower ];
  "secrets/hass-token.age".publicKeys = allWorkstations;
  "secrets/gmail-app-password.age".publicKeys = allLinuxWorkstations;
  "secrets/c411-api-key.age".publicKeys = [ tower ];
  "secrets/atuin-key.age".publicKeys = allMachines;
  "secrets/atuin-password.age".publicKeys = allMachines;
  "secrets/google-health-oauth-client.age".publicKeys = allWorkstations;
  "secrets/riot-api-key.age".publicKeys = [ daddy ];
  "secrets/harmonia-signing-key.age".publicKeys = [ tower ];
  "secrets/dispatch-claude-token.age".publicKeys = [ tower ];
  "secrets/dispatch-github-token.age".publicKeys = [ tower ];
  "secrets/syncthing-leod-cert.age".publicKeys = [ leod ];
  "secrets/syncthing-leod-key.age".publicKeys = [ leod ];
  "secrets/ssh-soft-leod.age".publicKeys = [ leod ];
  "secrets/leod-disk-passphrase.age".publicKeys = [ leod ];
  "secrets/leod-tpm-pin.age".publicKeys = [ leod ];
  "secrets/smb-credentials.age".publicKeys = [
    tower
    leod
  ];
}
