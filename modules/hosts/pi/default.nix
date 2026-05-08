{
  self,
  inputs,
  ...
}:
{
  flake.nixosConfigurations.pi = inputs.nixpkgs.lib.nixosSystem {
    specialArgs = {
      inherit (inputs) etiennerobert-com creatures;
      inherit self;
    };
    system = "aarch64-linux";
    modules = [
      ./configuration.nix
      self.nixosModules.nixosBase
      self.nixosModules.base
      self.nixosModules.server
      inputs.agenix.nixosModules.default
    ];
  };
}
