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
    };
}
