{
  self,
  inputs,
  ...
}:
let
  inherit (inputs)
    nix-darwin
    home-manager
    agenix
    # nixpkgs-darwin-pins
    ;
in
{
  flake.darwinConfigurations.aaron = nix-darwin.lib.darwinSystem {
    specialArgs = { inherit self agenix; };
    modules = [
      ./configuration.nix
      home-manager.darwinModules.home-manager
      agenix.darwinModules.default
      self.darwinModules.workstation
      self.darwinModules.base
      self.darwinModules.unfree
      self.darwinModules.nixIndex
    ];
  };
}
