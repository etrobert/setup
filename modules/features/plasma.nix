_: {
  flake.nixosModules.plasma = _: {
    # Ships a plasma session in services.displayManager.sessionData, which
    # tuigreet lists — pick it with F3 at the login prompt.
    services.desktopManager.plasma6.enable = true;
  };
}
