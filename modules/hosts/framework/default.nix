{
  self,
  inputs,
  ...
}:
{
  flake.nixosConfigurations.framework = inputs.nixpkgs.lib.nixosSystem {
    specialArgs = {
      inherit self;
      inherit (inputs) agenix;
    };
    modules = [
      self.nixosModules.framework-configuration
      inputs.nixos-hardware.nixosModules.framework-intel-core-ultra-series3
      inputs.agenix.nixosModules.default
      self.nixosModules.nixos-workstation
      self.nixosModules.workstation
      self.nixosModules.nixos-base
      self.nixosModules.base
      self.nixosModules.unfree
    ];
  };
}
