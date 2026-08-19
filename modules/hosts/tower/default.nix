{
  self,
  inputs,
  ...
}:
let
  inherit (inputs)
    nixpkgs
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
      self.nixosModules.nixIndex
      agenix.nixosModules.default
      self.nixosModules.nixosWorkstation
      self.nixosModules.workstation
      self.nixosModules.nixosBase
      self.nixosModules.base
      self.nixosModules.unfree
      self.nixosModules.server
      self.nixosModules.ntfy
      self.nixosModules.claudeWarmup
      self.nixosModules.docker
      self.nixosModules.gaming
      self.nixosModules.githubRunner
      self.nixosModules.harmonia
      self.nixosModules.navidrome
      self.nixosModules.homeAssistant
      self.nixosModules.towerStorage
      self.nixosModules.samba
      self.nixosModules.immich
      self.nixosModules.ollama
      self.nixosModules.comfyui
      self.nixosModules.openWebui
      self.nixosModules.tailnetServices
    ];
  };
}
