_: {
  flake.nixosModules.cachixPush =
    { config, ... }:
    {
      services.cachix-watch-store = {
        enable = true;
        cacheName = "soft-nix";
        cachixTokenFile = config.age.secrets.cachix-token.path;
      };
    };
}
