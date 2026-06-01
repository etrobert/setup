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
    etiennerobert-com
    creatures
    ;
in
{
  flake.nixosConfigurations.tower = nixpkgs.lib.nixosSystem {
    specialArgs = {
      inherit
        self
        agenix
        etiennerobert-com
        creatures
        ;
    };
    modules = [
      ./configuration.nix
      self.nixosModules.nixIndex
      home-manager.nixosModules.home-manager
      agenix.nixosModules.default
      self.nixosModules.nixosWorkstation
      self.nixosModules.workstation
      self.nixosModules.nixosBase
      self.nixosModules.base
      self.nixosModules.unfree
      self.nixosModules.server
      self.nixosModules.homepage
    ];
  };
}
