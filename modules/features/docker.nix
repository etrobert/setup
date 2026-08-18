_: {
  flake.nixosModules.docker = _: {
    # Docker daemon, for running containers (e.g. the nixos/nix image to get an
    # interactive Nix environment on machines without Nix).
    virtualisation.docker.enable = true;
    users.users.soft.extraGroups = [ "docker" ];
  };
}
