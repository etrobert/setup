_: {
  flake.nixosModules.cachix-push =
    { config, ... }:
    {
      age.secrets.cachix-token.file = ../secrets/cachix-token.age;

      services.cachix-watch-store = {
        enable = true;
        cacheName = "soft-nix";
        cachixTokenFile = config.age.secrets.cachix-token.path;
      };

      # cachix's HTTP client (Haskell) has no happy-eyeballs and hangs forever
      # in SYN-SENT when AAAA is reachable in routing but not actually routed.
      # Tower's router-advertised IPv6 default is exactly that — so deny IPv6
      # sockets for this service and the client falls through to A.
      # TODO: remove once home IPv6 routing is fixed.
      systemd.services.cachix-watch-store-agent.serviceConfig.RestrictAddressFamilies = [
        "AF_UNIX"
        "AF_INET"
      ];
    };
}
