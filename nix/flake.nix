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
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                users.soft = import ./modules/home/${if darwin then "darwin.nix" else "linux.nix"};
              };
            }
          ]
          # TODO: Remove once we make usernames uniform
          ++ (
            if darwin then [ { home-manager.users.etiennerobert = import ./modules/home/darwin.nix; } ] else [ ]
          );
        };
      mkNixosHost = mkHost { darwin = false; };
      mkDarwinHost = mkHost { darwin = true; };

      inherit (nixpkgs.lib) genAttrs;

      nixosHosts = [
        "tower"
        "leod"
      ];

      darwinHosts = [ "aaron" ];
    in
    {
      nixosConfigurations = genAttrs nixosHosts mkNixosHost;

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
        in
        {
          "soft@tower" = mkHome {
            system = "x86_64-linux";
            module = ./modules/home/linux.nix;
            username = "soft";
          };
          "soft@leod" = mkHome {
            system = "x86_64-linux";
            module = ./modules/home/linux.nix;
            username = "soft";
          };
          "soft@aaron" = mkHome {
            system = "aarch64-darwin";
            module = ./modules/home/darwin.nix;
            username = "soft";
          };
        };

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
