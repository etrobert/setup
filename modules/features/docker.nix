_: {
  flake.nixosModules.docker = _: {
    # e.g. the nixos/nix image, for an interactive Nix environment on machines without Nix
    virtualisation.docker.enable = true;
    users.users.soft.extraGroups = [ "docker" ];
  };
}
