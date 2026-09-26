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
      self.nixosModules.pi-configuration
      self.nixosModules.nixos-base
      self.nixosModules.base
      self.nixosModules.lan-dns
      self.nixosModules.node-exporter
      self.nixosModules.syncthing
      self.nixosModules.atuin-login
      self.nixosModules.auto-upgrade
      inputs.agenix.nixosModules.default
    ];
  };
}
