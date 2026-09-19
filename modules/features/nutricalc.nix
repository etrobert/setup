# A friend's project, hosted at his request. The input is not ours, so his
# pushes to main get deployed through the hourly flake-update PR without review.
{ inputs, ... }:
{
  flake.nixosModules.nutricalc = _: {
    imports = [ inputs.nutricalc.nixosModules.default ];

    services.nutricalc = {
      enable = true;
      hostName = "nutricalc.etiennerobert.com";
    };
  };
}
