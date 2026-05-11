let
  # Machine host public keys (from /etc/ssh/ssh_host_ed25519_key.pub)
  tower = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHagaONxn4Ua5dkPfiGuavydHFfIEUVWMBrZHsucIILT";
  leod = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBgObi3D4k+OGPizrmEnHVKRcl6tuMsrAyP54LL6SVRi";
  aaron = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICvejXYLtulpvy+h311SuQVlpQhaNBh7LO5zGbazd2bh";
  pi = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMbTCtRJeFqky1PSKe45KI0aMhpKqgd32Z9Fy9S4Op89";

  allLinux = [
    tower
    leod
    pi
  ];
  allMachines = allLinux ++ [ aaron ];
in
{
  "openai-api-key.age".publicKeys = allMachines;
  "gemini-api-key.age".publicKeys = allMachines;
  "wifi-soft.age".publicKeys = allLinux;
  "wifi-iphone-de-zeus.age".publicKeys = allLinux;
  "wifi-vinni.age".publicKeys = allLinux;
  "tailscale-authkey.age".publicKeys = allMachines;
  "apple-pimsync-password.age".publicKeys = allLinux; # TODO: Restrict to linux workstations
  "soft-password.age".publicKeys = allLinux;
  # TODO: Restrict to relevant machines
  "ddclient-password-etiennerobert-com.age".publicKeys = allLinux;
}
