{
  flake.nixosModules.virtualbox = {
    virtualisation.virtualbox.host.enable = true;
    # Required for passing USB devices through to guests.
    users.users.soft.extraGroups = [ "vboxusers" ];
  };
}
