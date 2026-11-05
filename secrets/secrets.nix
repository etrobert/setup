let
  inherit (import ./host-keys.nix)
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
  "openai-api-key.age".publicKeys = allWorkstations;
  "gemini-api-key.age".publicKeys = allWorkstations;
  "wifi-soft.age".publicKeys = allLinuxWorkstations;
  "wifi-iphone-de-zeus.age".publicKeys = allLinuxWorkstations;
  "wifi-vinni.age".publicKeys = allLinuxWorkstations;
  "tailscale-authkey.age".publicKeys = allMachines;
  "apple-pimsync-password.age".publicKeys = allLinuxWorkstations;
  "soft-password.age".publicKeys = allLinux;
  "ddclient-password-etiennerobert-com.age".publicKeys = [ tower ];
  "umami-app-secret.age".publicKeys = [ daddy ];
  "nix-access-tokens.age".publicKeys = allWorkstations;
  "github-runner-token.age".publicKeys = allWorkstations;
  # Fine-grained tokens carry one resource owner, so lafraise-pro/app cannot
  # share the one above. Unused since the runner moved off tower; kept in case.
  "lafraise-runner-token.age".publicKeys = [ tower ];
  "hass-token.age".publicKeys = allWorkstations;
  "c411-api-key.age".publicKeys = [
    tower
    peira
  ];
  "atuin-key.age".publicKeys = allMachines;
  "atuin-password.age".publicKeys = allMachines;
  "google-health-oauth-client.age".publicKeys = allWorkstations;
  "riot-api-key.age".publicKeys = [ daddy ];
  "harmonia-signing-key.age".publicKeys = [ tower ];
  "dispatch-claude-token.age".publicKeys = [ tower ];
  "dispatch-github-token.age".publicKeys = [ tower ];
  "syncthing-leod-cert.age".publicKeys = [ leod ];
  "syncthing-leod-key.age".publicKeys = [ leod ];
  "ssh-soft-leod.age".publicKeys = [ leod ];
  "leod-disk-passphrase.age".publicKeys = [ leod ];
  "leod-tpm-pin.age".publicKeys = [ leod ];
  "smb-credentials.age".publicKeys = [
    tower
    leod
  ];
}
