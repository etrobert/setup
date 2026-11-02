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
      self.nixosModules.charon-configuration
      self.nixosModules.nixos-base
      self.nixosModules.base
      self.nixosModules.tailnet-services
      self.nixosModules.transmission
      self.nixosModules.node-exporter
      self.nixosModules.atuin-login
      inputs.agenix.nixosModules.default
    ];
  };
}
