_: {
  flake.nixosModules.gaming = _: {
    programs.steam.enable = true;

    allowedUnfreePackages = [
      "steam"
      "steam-unwrapped"
    ];
  };
}
