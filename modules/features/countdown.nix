{ inputs, ... }:
{
  flake.nixosModules.countdown = _: {
    imports = [ inputs.countdown.nixosModules.default ];

    services.countdown = {
      enable = true;
      hostName = "countdown.etiennerobert.com";
    };
  };
}
