{
  self,
  inputs,
  ...
}:
let
  inherit (inputs)
    nixpkgs
    home-manager
    agenix
    ;
in
{
  flake.nixosConfigurations.tower = nixpkgs.lib.nixosSystem {
    specialArgs = {
      inherit
        self
        agenix
        ;
    };
    modules = [
      self.nixosModules.towerConfiguration
      home-manager.nixosModules.home-manager
      agenix.nixosModules.default
      self.nixosModules.nixosWorkstation
      self.nixosModules.workstation
      self.nixosModules.nixosBase
      self.nixosModules.server
      self.nixosModules.ntfy
      self.nixosModules.homepage
      self.nixosModules.claudeWarmup
      self.nixosModules.gaming
      self.nixosModules.githubRunner
      self.nixosModules.harmonia
      self.nixosModules.navidrome
      self.nixosModules.homeAssistant
    ];
  };
}
