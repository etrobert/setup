let
  # Machine host public keys (from /etc/ssh/ssh_host_ed25519_key.pub)
  tower = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHagaONxn4Ua5dkPfiGuavydHFfIEUVWMBrZHsucIILT";
  leod = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBgObi3D4k+OGPizrmEnHVKRcl6tuMsrAyP54LL6SVRi";

  # aaron = "ssh-ed25519 ...";

  allLinux = [
    tower
    leod
  ];
  allMachines = allLinux; # ++ [ aaron ];
in
{
  # Example:
  # "secret-name.age".publicKeys = allLinux;
  "openai-api-key.age".publicKeys = allMachines;
}
