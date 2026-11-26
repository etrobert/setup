let
  inherit (import ./secrets/host-keys.nix)
    tower
    leod
    aaron
    pi
    daddy
    peira
    ;
  inherit ((import ./modules/lib/ssh-keys.nix).flake.lib.sshKeys) soft;

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
# soft's keys can decrypt every secret, so editing needs no host key.
builtins.mapAttrs (_: hosts: { publicKeys = soft ++ hosts; }) {
  "secrets/openai-api-key.age" = allWorkstations;
  "secrets/gemini-api-key.age" = allWorkstations;
  "secrets/wifi-soft.age" = allLinuxWorkstations;
  "secrets/wifi-iphone-de-zeus.age" = allLinuxWorkstations;
  "secrets/wifi-vinni.age" = allLinuxWorkstations;
  "secrets/tailscale-authkey.age" = allMachines;
  "secrets/apple-pimsync-password.age" = allLinuxWorkstations;
  "secrets/soft-password.age" = allLinux;
  "secrets/ddclient-password-etiennerobert-com.age" = [ tower ];
  "secrets/umami-app-secret.age" = [ daddy ];
  "secrets/nix-access-tokens.age" = allWorkstations;
  "secrets/github-runner-token.age" = allWorkstations;
  # Fine-grained tokens carry one resource owner, so lafraise-pro/app cannot
  # share the one above. Unused since the runner moved off tower; kept in case.
  "secrets/lafraise-runner-token.age" = [ tower ];
  "secrets/hass-token.age" = allWorkstations;
  "secrets/gmail-app-password.age" = allLinuxWorkstations;
  "secrets/c411-api-key.age" = [ tower ];
  "secrets/atuin-key.age" = allMachines;
  "secrets/atuin-password.age" = allMachines;
  "secrets/google-health-oauth-client.age" = allWorkstations;
  "secrets/riot-api-key.age" = [ daddy ];
  "secrets/harmonia-signing-key.age" = [ tower ];
  "secrets/dispatch-claude-token.age" = [ tower ];
  "secrets/dispatch-github-token.age" = [ tower ];
  "secrets/syncthing-leod-cert.age" = [ leod ];
  "secrets/syncthing-leod-key.age" = [ leod ];
  "secrets/ssh-soft-leod.age" = [ leod ];
  "secrets/leod-disk-passphrase.age" = [ leod ];
  "secrets/leod-tpm-pin.age" = [ leod ];
  "secrets/smb-credentials.age" = [
    tower
    leod
  ];
}
