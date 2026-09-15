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
  flake.nixosConfigurations.leod = nixpkgs.lib.nixosSystem {
    specialArgs = { inherit self agenix; };
    modules = [
      self.nixosModules.leodConfiguration
      self.nixosModules.docker
      self.nixosModules.tankMount
      self.nixosModules.nixIndex
      self.nixosModules.ankamaLauncher
      agenix.nixosModules.default
      self.nixosModules.nixosWorkstation
      self.nixosModules.workstation
      self.nixosModules.nixosBase
      self.nixosModules.base
      self.nixosModules.unfree
    ];
  };
}
