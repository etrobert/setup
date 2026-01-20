{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pronto = {
      url = "github:etrobert/pronto";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      neovim-nightly-overlay,
      nix-darwin,
      pronto,
      home-manager,
    }:
    {
      nixosConfigurations = {
        tower = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit pronto; };
          modules = [
            ./hosts/tower/configuration.nix
            {
              nixpkgs.overlays = [ neovim-nightly-overlay.overlays.default ];
            }
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.soft = import ./modules/home.nix;
            }
          ];
        };

        leod = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit pronto; };
          modules = [
            ./hosts/leod/configuration.nix
            {
              nixpkgs.overlays = [ neovim-nightly-overlay.overlays.default ];
            }
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.soft = import ./modules/home.nix;
            }
          ];
        };
      };

      darwinConfigurations = {
        aaron = nix-darwin.lib.darwinSystem {
          specialArgs = { inherit pronto; };
          modules = [
            ./hosts/aaron/configuration.nix
            {
              nixpkgs.overlays = [ neovim-nightly-overlay.overlays.default ];
            }
            home-manager.darwinModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.soft = import ./modules/home-darwin.nix;
            }
          ];
        };
      };
    };
}
