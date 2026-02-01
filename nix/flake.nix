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
      overlayModule = {
        nixpkgs.overlays = [ neovim-nightly-overlay.overlays.default ];
      };

      nixosHosts = [
        "tower"
        "leod"
      ];
      darwinHosts = [ "aaron" ];

      platformConfig = {
        nixos = {
          builder = nixpkgs.lib.nixosSystem;
          system = "x86_64-linux";
          homeModule = ./modules/home/linux.nix;
          agenixModule = agenix.nixosModules.default;
          homeManagerModule = home-manager.nixosModules.home-manager;
          extraModules = [ ];
        };
        darwin = {
          builder = nix-darwin.lib.darwinSystem;
          system = "aarch64-darwin";
          homeModule = ./modules/home/darwin.nix;
          agenixModule = agenix.darwinModules.default;
          homeManagerModule = home-manager.darwinModules.home-manager;
          # TODO: Remove once we make usernames uniform
          extraModules = [
            { home-manager.users.etiennerobert = import ./modules/home/darwin.nix; }
          ];
        };
      };

      mkHost =
        platform: host:
        let
          cfg = platformConfig.${platform};
        in
        cfg.builder {
          specialArgs = { inherit pronto agenix; };
          modules = [
            ./hosts/${host}/configuration.nix
            overlayModule
            cfg.agenixModule
            cfg.homeManagerModule
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                users.soft = import cfg.homeModule;
              };
            }
          ]
          ++ cfg.extraModules;
        };

      mkHome =
        platform:
        let
          cfg = platformConfig.${platform};
        in
        home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${cfg.system};
          modules = [
            overlayModule
            { home.username = "soft"; }
            cfg.homeModule
          ];
        };

      inherit (nixpkgs.lib) genAttrs;
    in
    {
      nixosConfigurations = genAttrs nixosHosts (mkHost "nixos");

      darwinConfigurations = genAttrs darwinHosts (mkHost "darwin");

      homeConfigurations =
        genAttrs (map (h: "soft@${h}") nixosHosts) (_: mkHome "nixos")
        // genAttrs (map (h: "soft@${h}") darwinHosts) (_: mkHome "darwin");

      formatter = nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-darwin" ] (
        system: nixpkgs.legacyPackages.${system}.nixfmt
      );

      devShells = nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-darwin" ] (system: {
        default = nixpkgs.legacyPackages.${system}.mkShell {
          packages = with nixpkgs.legacyPackages.${system}; [
            statix
            deadnix
            nixfmt
          ];
        };
      });

      checks = nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-darwin" ] (system: {
        statix =
          nixpkgs.legacyPackages.${system}.runCommand "statix-check"
            {
              nativeBuildInputs = [ nixpkgs.legacyPackages.${system}.statix ];
            }
            ''
              statix check ${self} && touch $out
            '';
        deadnix =
          nixpkgs.legacyPackages.${system}.runCommand "deadnix-check"
            {
              nativeBuildInputs = [ nixpkgs.legacyPackages.${system}.deadnix ];
            }
            ''
              deadnix --fail ${self} && touch $out
            '';
      });
    };
}
