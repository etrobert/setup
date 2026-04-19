{
  self,
  inputs,
  ...
}:
let
  inherit (inputs)
    nixpkgs
    nix-index-database
    home-manager
    pronto
    agenix
    ;
in
{
  flake.nixosConfigurations.tower = nixpkgs.lib.nixosSystem {
    specialArgs = {
      inherit
        self
        pronto
        agenix
        ;
    };
    modules = [
      ./configuration.nix
      nix-index-database.nixosModules.default
      home-manager.nixosModules.home-manager
      agenix.nixosModules.default
      self.nixosModules.nixosWorkstation
      self.nixosModules.workstation
      self.nixosModules.nixosBase
      self.nixosModules.base
      self.nixosModules.unfree
    ];
  };
}
