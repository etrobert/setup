let
  # Machine host public keys (from /etc/ssh/ssh_host_ed25519_key.pub)
  tower = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHagaONxn4Ua5dkPfiGuavydHFfIEUVWMBrZHsucIILT";
  # leod = "ssh-ed25519 ...";
  # aaron = "ssh-ed25519 ...";

  allLinux = [ tower ]; # add leod when available
  allMachines = allLinux; # ++ [ aaron ];
in
{
  # Example:
  # "secret-name.age".publicKeys = allLinux;
  "openai-api-key.age".publicKeys = allMachines;
}
