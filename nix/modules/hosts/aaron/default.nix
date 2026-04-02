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
    ;
in
{
  flake.darwinConfigurations.aaron = nix-darwin.lib.darwinSystem {
    specialArgs = { inherit self pronto agenix; };
    modules = [
      ./configuration.nix
      nix-index-database.darwinModules.nix-index
      home-manager.darwinModules.home-manager
      agenix.darwinModules.default
      self.darwinModules.workstation
      self.darwinModules.base
      self.darwinModules.unfree
    ];
  };
}
