{
  # Substituters used when building this flake on a machine that has not yet
  # activated this config (e.g. CI, fresh installs, new machines). On machines
  # that have already activated this config, nix.settings takes over instead.
  nixConfig = {
    extra-substituters = [ "https://nix-community.cachix.org" ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    neovim-nightly-overlay = {
      url = "github:nix-community/neovim-nightly-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
          ];
        };
      mkNixosHost = mkHost {
        builder = nixpkgs.lib.nixosSystem;
        agenixModule = agenix.nixosModules.default;
        homeManagerModule = home-manager.nixosModules.home-manager;
        homeModule = ./modules/home/linux.nix;
      };
      mkDarwinHost = mkHost {
        builder = nix-darwin.lib.darwinSystem;
        agenixModule = agenix.darwinModules.default;
        homeManagerModule = home-manager.darwinModules.home-manager;
        homeModule = ./modules/home/darwin.nix;
      };

      inherit (nixpkgs.lib) genAttrs;

      nixosHosts = [
        "tower"
        "leod"
      ];

      darwinHosts = [ "aaron" ];
    in
    {
      nixosConfigurations = genAttrs nixosHosts mkNixosHost // {
        pi = nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          modules = [
            ./hosts/pi/configuration.nix
            agenix.nixosModules.default
          ];
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
        };

      formatter = nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-darwin" ] (
        system: nixpkgs.legacyPackages.${system}.nixfmt
      );

      devShells = nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-darwin" ] (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            packages = with pkgs; [
              statix
              deadnix
              nixfmt
            ];
          };
          pimsync = pkgs.mkShell {
            packages = [
              (pkgs.python3.withPackages (ps: with ps; [ vobject ]))
            ];
          };
        }
      );

      checks = nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-darwin" ] (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          statix = pkgs.runCommand "statix-check" { nativeBuildInputs = [ pkgs.statix ]; } ''
            statix check ${self} && touch $out
          '';
          deadnix = pkgs.runCommand "deadnix-check" { nativeBuildInputs = [ pkgs.deadnix ]; } ''
            deadnix --fail ${self} && touch $out
          '';
        }
      );
    };
}
