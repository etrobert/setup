{ lib, ... }:
{
  # Hashed from the name, so adding a service never moves another's port.
  # A clash is not caught here: the second service fails to bind at start.
  flake.lib.portFor =
    name:
    20000
    + lib.mod (lib.fromHexString (builtins.substring 0 8 (builtins.hashString "sha256" name))) 10000;
}
