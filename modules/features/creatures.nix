{ inputs, ... }:
{
  flake.nixosModules.creatures = _: {
    imports = [ inputs.creatures.nixosModules.default ];

    services.creatures = {
      enable = true;
      hostName = "creatures.etiennerobert.com";
    };
  };
}
