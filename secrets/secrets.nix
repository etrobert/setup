let
  # Machine host public keys (from /etc/ssh/ssh_host_ed25519_key.pub)
  tower = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHagaONxn4Ua5dkPfiGuavydHFfIEUVWMBrZHsucIILT";
  leod = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBgObi3D4k+OGPizrmEnHVKRcl6tuMsrAyP54LL6SVRi";
  aaron = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICvejXYLtulpvy+h311SuQVlpQhaNBh7LO5zGbazd2bh";
  pi = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMbTCtRJeFqky1PSKe45KI0aMhpKqgd32Z9Fy9S4Op89";
  charon = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKjmj/dwNIYcHnshGmTzVXIBqHCWeOXmgmNbEuLWWsK/";

  allLinux = [
    tower
    leod
    pi
    charon
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
  # Hardware we hold; charon is rented.
  allOwned = [
    tower
    leod
    pi
    aaron
  ];
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
  "umami-app-secret.age".publicKeys = [ tower ];
  "nix-access-tokens.age".publicKeys = allWorkstations;
  "github-runner-token.age".publicKeys = allWorkstations;
  # Fine-grained tokens carry one resource owner, so lafraise-pro/app cannot
  # share the one above. Unused since the runner moved off tower; kept in case.
  "lafraise-runner-token.age".publicKeys = [ tower ];
  "z-ai-auth-token.age".publicKeys = allWorkstations;
  "hass-token.age".publicKeys = allWorkstations;
  "atuin-key.age".publicKeys = allOwned;
  "atuin-password.age".publicKeys = allOwned;
  "google-health-oauth-client.age".publicKeys = allWorkstations;
  "riot-api-key.age".publicKeys = [ tower ];
  "harmonia-signing-key.age".publicKeys = [ tower ];
  "dispatch-claude-token.age".publicKeys = [ tower ];
  "dispatch-github-token.age".publicKeys = [ tower ];
  "smb-credentials.age".publicKeys = [
    tower
    leod
  ];
}
