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
    agenix = {
      url = "github:ryantm/agenix";
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
      agenix,
    }:
    let
      mkHost =
        { darwin }:
        host:
        let
          builder = if darwin then nix-darwin.lib.darwinSystem else nixpkgs.lib.nixosSystem;
        in
        builder {
          specialArgs = { inherit pronto agenix; };
          modules = [
            ./hosts/${host}/configuration.nix
            {
              nixpkgs.overlays = [ neovim-nightly-overlay.overlays.default ];
            }
            agenix.${if darwin then "darwinModules" else "nixosModules"}.default
            home-manager.${if darwin then "darwinModules" else "nixosModules"}.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
            }
            (
              if darwin then
                {
                  home-manager.users.soft = import ./modules/home/darwin.nix;
                  home-manager.users.etiennerobert = import ./modules/home/darwin.nix;
                }
              else
                {
                  home-manager.users.soft = import ./modules/home/linux.nix;
                }
            )
          ];
        };
      mkNixosHost = mkHost { darwin = false; };
      mkDarwinHost = mkHost { darwin = true; };
    in
    {
      nixosConfigurations = {
        tower = mkNixosHost "tower";
        leod = mkNixosHost "leod";
      };

      darwinConfigurations = {
        aaron = mkDarwinHost "aaron";
      };
    };
}
