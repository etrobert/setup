_: {
  flake.nixosModules.cockpit = _: {
    services.cockpit = {
      enable = true;
      # Reachable on the LAN only — the home router doesn't forward 9090.
      openFirewall = true;
      allowed-origins = [
        "https://tower:9090"
        "https://tower.lan:9090"
        "https://192.168.0.130:9090"
        "https://localhost:9090"
      ];
    };
  };
}
