{
  self,
  inputs,
  ...
}:
{
  flake.nixosConfigurations.ovh = inputs.nixpkgs.lib.nixosSystem {
    specialArgs = { inherit self; };
    system = "x86_64-linux";
    modules = [
      self.nixosModules.ovhConfiguration
      self.nixosModules.nixosBase
      self.nixosModules.base
      self.nixosModules.autoUpgrade
      inputs.agenix.nixosModules.default
    ];
  };
}
