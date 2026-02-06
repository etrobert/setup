let
  # Machine host public keys (from /etc/ssh/ssh_host_ed25519_key.pub)
  tower = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHagaONxn4Ua5dkPfiGuavydHFfIEUVWMBrZHsucIILT";
  leod = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBgObi3D4k+OGPizrmEnHVKRcl6tuMsrAyP54LL6SVRi";
  aaron = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG/Y38NV8a/9rfDq+7W1UFfAFDo8SkwQ5JAl/U24u0ne";

  allLinux = [
    tower
    leod
  ];
  allMachines = allLinux ++ [ aaron ];
in
{
  "openai-api-key.age".publicKeys = allMachines;
  "gemini-api-key.age".publicKeys = allMachines;
  "wifi-soft.age".publicKeys = allLinux;
  "wifi-iphone-de-zeus.age".publicKeys = allLinux;
}
