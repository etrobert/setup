_: {
  flake.nixosModules.caddy = _: {
    services.caddy.enable = true;

    networking.firewall.allowedTCPPorts = [
      80
      443
    ];
  };
}
