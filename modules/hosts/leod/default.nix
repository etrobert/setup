{
  self,
  inputs,
  ...
}:
let
  inherit (inputs)
    nixpkgs
    agenix
    ;
in
{
  flake.nixosConfigurations.leod = nixpkgs.lib.nixosSystem {
    specialArgs = { inherit self agenix; };
    modules = [
      self.nixosModules.leod-configuration
      self.nixosModules.docker
      self.nixosModules.tank-mount
      self.nixosModules.nix-index
      self.nixosModules.ankama-launcher
      agenix.nixosModules.default
      self.nixosModules.nixos-workstation
      self.nixosModules.workstation
      self.nixosModules.nixos-base
      self.nixosModules.base
      self.nixosModules.unfree
    ];
  };
}
