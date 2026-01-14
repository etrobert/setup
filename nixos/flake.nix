{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    pronto = {
      url = "github:etrobert/pronto";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      neovim-nightly-overlay,
      pronto,
    }:
    {
      nixosConfigurations = {
        tower = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit pronto; };
          modules = [
            ./hosts/tower/configuration.nix
            {
              nixpkgs.overlays = [ neovim-nightly-overlay.overlays.default ];
            }
          ];
        };

        leod = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit pronto; };
          modules = [
            ./hosts/leod/configuration.nix
            {
              nixpkgs.overlays = [ neovim-nightly-overlay.overlays.default ];
            }
          ];
        };
      };
    };
}
