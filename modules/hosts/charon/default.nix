{
  self,
  inputs,
  ...
}:
{
  flake.nixosConfigurations.charon = inputs.nixpkgs.lib.nixosSystem {
    specialArgs = { inherit self; };
    system = "x86_64-linux";
    modules = [
      self.nixosModules.charonConfiguration
      self.nixosModules.nixosBase
      self.nixosModules.base
      self.nixosModules.autoUpgrade
      self.nixosModules.tailnetServices
      self.nixosModules.transmission
      self.nixosModules.nodeExporter
      self.nixosModules.caddy
      self.nixosModules.draw
      self.nixosModules.ddclient
      inputs.agenix.nixosModules.default
    ];
  };
}
