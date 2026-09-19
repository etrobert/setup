{
  self,
  inputs,
  ...
}:
{
  flake.nixosConfigurations.pi = inputs.nixpkgs.lib.nixosSystem {
    specialArgs = { inherit self; };
    system = "aarch64-linux";
    modules = [
      self.nixosModules.piConfiguration
      self.nixosModules.nixosBase
      self.nixosModules.base
      self.nixosModules.lanDns
      self.nixosModules.nodeExporter
      self.nixosModules.syncthing
      self.nixosModules.atuinLogin
      self.nixosModules.autoUpgrade
      inputs.agenix.nixosModules.default
    ];
  };
}
