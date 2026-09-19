_: {
  flake.nixosModules.caddy = _: {
    services.caddy = {
      enable = true;
      openFirewall = true;
    };
  };
}
