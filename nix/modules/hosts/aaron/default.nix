{
  self,
  inputs,
  ...
}:
let
  inherit (inputs)
    nix-darwin
    nix-index-database
    home-manager
    pronto
    agenix
    neovim-nightly-overlay
    ;
in
{
  flake.darwinConfigurations.aaron = nix-darwin.lib.darwinSystem {
    specialArgs = { inherit self pronto agenix; };
    modules = [
      ./configuration.nix
      { nixpkgs.overlays = [ neovim-nightly-overlay.overlays.default ]; }
      nix-index-database.darwinModules.nix-index
      home-manager.darwinModules.home-manager
      agenix.darwinModules.default
      self.darwinModules.workstation
      self.darwinModules.base
      self.darwinModules.unfree
    ];
  };
}
