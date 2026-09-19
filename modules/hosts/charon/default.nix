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
      inputs.agenix.nixosModules.default
    ];
  };
}
