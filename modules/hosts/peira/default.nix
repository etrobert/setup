{
  self,
  inputs,
  ...
}:
{
  flake.nixosConfigurations.peira = inputs.nixpkgs.lib.nixosSystem {
    specialArgs = { inherit self; };
    system = "x86_64-linux";
    modules = [
      self.nixosModules.peira-configuration
      self.nixosModules.nixos-base
      self.nixosModules.base
      self.nixosModules.tailnet-services
      inputs.agenix.nixosModules.default
    ];
  };
}
