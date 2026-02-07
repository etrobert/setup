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
        {
          builder,
          agenixModule,
          homeManagerModule,
          homeModule,
          extraModules,
        }:
        host:
        builder {
          specialArgs = { inherit pronto agenix; };
          modules = [
            ./hosts/${host}/configuration.nix
            { nixpkgs.overlays = [ neovim-nightly-overlay.overlays.default ]; }
            agenixModule
            homeManagerModule
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                users.soft = import homeModule;
              };
            }
          ]
          # TODO: Remove once we make usernames uniform
          ++ extraModules;
        };
      mkNixosHost = mkHost {
        builder = nixpkgs.lib.nixosSystem;
        agenixModule = agenix.nixosModules.default;
        homeManagerModule = home-manager.nixosModules.home-manager;
        homeModule = ./modules/home/linux.nix;
        extraModules = [ ];
      };
      mkDarwinHost = mkHost {
        builder = nix-darwin.lib.darwinSystem;
        agenixModule = agenix.darwinModules.default;
        homeManagerModule = home-manager.darwinModules.home-manager;
        homeModule = ./modules/home/darwin.nix;
        extraModules = [ { home-manager.users.etiennerobert = import ./modules/home/darwin.nix; } ];
      };

      inherit (nixpkgs.lib) genAttrs;

      nixosHosts = [
        "tower"
        "leod"
      ];

      darwinHosts = [ "aaron" ];

      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
    in
    {
      nixosConfigurations = genAttrs nixosHosts mkNixosHost // {
        pi = nixpkgs.lib.nixosSystem {
          modules = [ ./hosts/pi/configuration.nix ];
        };
      };

      darwinConfigurations = genAttrs darwinHosts mkDarwinHost;

      homeConfigurations =
        let
          mkHome =
            {
              system,
              module,
              username,
            }:
            home-manager.lib.homeManagerConfiguration {
              pkgs = nixpkgs.legacyPackages.${system};
              modules = [
                { nixpkgs.overlays = [ neovim-nightly-overlay.overlays.default ]; }
                { home.username = username; }
                module
              ];
            };
          mkLinuxHome = mkHome {
            system = "x86_64-linux";
            module = ./modules/home/linux.nix;
            username = "soft";
          };
          mkDarwinHome = mkHome {
            system = "aarch64-darwin";
            module = ./modules/home/darwin.nix;
            username = "soft";
          };
        in
        {
          "soft@tower" = mkLinuxHome;
          "soft@leod" = mkLinuxHome;
          "soft@aaron" = mkDarwinHome;
          "etiennerobert@aaron" = mkHome {
            system = "aarch64-darwin";
            module = ./modules/home/darwin.nix;
            username = "etiennerobert";
          };
        };

      formatter = genAttrs systems (
        system: nixpkgs.legacyPackages.${system}.nixfmt
      );

      devShells = genAttrs systems (system: {
        default = nixpkgs.legacyPackages.${system}.mkShell {
          packages = with nixpkgs.legacyPackages.${system}; [
            statix
            deadnix
            nixfmt
          ];
        };
      });

      checks = genAttrs systems (system: {
        statix =
          nixpkgs.legacyPackages.${system}.runCommand "statix-check"
            { nativeBuildInputs = [ nixpkgs.legacyPackages.${system}.statix ]; }
            ''
              statix check ${self} && touch $out
            '';
        deadnix =
          nixpkgs.legacyPackages.${system}.runCommand "deadnix-check"
            { nativeBuildInputs = [ nixpkgs.legacyPackages.${system}.deadnix ]; }
            ''
              deadnix --fail ${self} && touch $out
            '';
      });
    };
}
