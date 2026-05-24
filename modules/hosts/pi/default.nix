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
      ./configuration.nix
      self.nixosModules.nixosBase
      self.nixosModules.base
      self.nixosModules.lanDns
      inputs.agenix.nixosModules.default
    ];
  };
}
