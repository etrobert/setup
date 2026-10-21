{
  self,
  inputs,
  ...
}:
let
  inherit (inputs)
    nixpkgs
    sops-nix
    ;
in
{
  flake.nixosConfigurations.leod = nixpkgs.lib.nixosSystem {
    specialArgs = { inherit self; };
    modules = [
      self.nixosModules.leod-configuration
      self.nixosModules.docker
      self.nixosModules.tank-mount
      self.nixosModules.nix-index
      self.nixosModules.ankama-launcher
      sops-nix.nixosModules.sops
      self.nixosModules.nixos-workstation
      self.nixosModules.workstation
      self.nixosModules.nixos-base
      self.nixosModules.base
      self.nixosModules.unfree
    ];
  };
}
