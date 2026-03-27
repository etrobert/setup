{
  self,
  inputs,
  ...
}:
let
  inherit (inputs)
    nixpkgs
    nix-index-database
    home-manager
    pronto
    agenix
    neovim-nightly-overlay
    ;
in
{
  flake.nixosConfigurations.tower = nixpkgs.lib.nixosSystem {
    specialArgs = { inherit self pronto agenix; };
    modules = [
      ./configuration.nix
      { nixpkgs.overlays = [ neovim-nightly-overlay.overlays.default ]; }
      nix-index-database.nixosModules.default
      home-manager.nixosModules.home-manager
      agenix.nixosModules.default
      self.nixosModules.nixosWorkstation
      self.nixosModules.workstation
      self.nixosModules.nixosBase
      self.nixosModules.base
      self.nixosModules.unfree
    ];
  };
}
