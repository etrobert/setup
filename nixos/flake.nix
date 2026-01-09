{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
  };

  outputs =
    {
      self,
      nixpkgs,
      neovim-nightly-overlay,
    }:
    {
      nixosConfigurations = {
        tower = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./hosts/tower/configuration.nix
            {
              nixpkgs.overlays = [ neovim-nightly-overlay.overlays.default ];
            }
          ];
        };

        leod = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
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
