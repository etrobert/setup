{
  self,
  inputs,
  ...
}:
let
  inherit (inputs)
    nixpkgs
    home-manager
    agenix
    ;
in
{
  flake.nixosConfigurations.leod = nixpkgs.lib.nixosSystem {
    specialArgs = { inherit self agenix; };
    modules = [
      self.nixosModules.leodConfiguration
      home-manager.nixosModules.home-manager
      agenix.nixosModules.default
      self.nixosModules.nixosWorkstation
      self.nixosModules.workstation
      self.nixosModules.nixosBase
      self.nixosModules.hypridle
    ];
  };
}
