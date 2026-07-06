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
    nix-homebrew
    nixpkgs-darwin-pins
    ;
in
{
  flake.darwinConfigurations.aaron = nix-darwin.lib.darwinSystem {
    specialArgs = {
      inherit
        self
        agenix
        nixpkgs-darwin-pins
        nix-darwin
        ;
    };
    modules = [
      ./configuration.nix
      home-manager.darwinModules.home-manager
      agenix.darwinModules.default
      nix-homebrew.darwinModules.nix-homebrew
      {
        nix-homebrew = {
          enable = true;
          enableRosetta = true;
          user = "soft";
        };
      }
      self.darwinModules.workstation
      self.darwinModules.base
      self.darwinModules.unfree
      self.darwinModules.nixIndex
      self.darwinModules.ntfyDesktop
    ];
  };
}
