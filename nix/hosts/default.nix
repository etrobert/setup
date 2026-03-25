{ self, inputs, ... }:
let
  inherit (inputs)
    nixpkgs
    nix-darwin
    home-manager
    agenix
    neovim-nightly-overlay
    pronto
    ;

  localPackagesOverlay = final: _prev: import ../pkgs { pkgs = final; };

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
        ./${host}/configuration.nix
        {
          nixpkgs.overlays = [
            neovim-nightly-overlay.overlays.default
            localPackagesOverlay
          ];
        }
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
      ++ extraModules;
    };

  mkNixosHost = mkHost {
    builder = nixpkgs.lib.nixosSystem;
    agenixModule = agenix.nixosModules.default;
    homeManagerModule = home-manager.nixosModules.home-manager;
    homeModule = ../modules/home/linux.nix;
    extraModules = [
      self.nixosModules.nixosWorkstation
      self.sharedModules.workstation
      self.nixosModules.nixosBase
      self.sharedModules.base
    ];
  };

  mkDarwinHost = mkHost {
    builder = nix-darwin.lib.darwinSystem;
    agenixModule = agenix.darwinModules.default;
    homeManagerModule = home-manager.darwinModules.home-manager;
    homeModule = ../modules/home/darwin.nix;
    extraModules = [
      self.sharedModules.workstation
      self.sharedModules.base
    ];
  };

  inherit (nixpkgs.lib) genAttrs;

  nixosHosts = [
    "tower"
    "leod"
  ];

  darwinHosts = [ "aaron" ];
in
{
  flake = {
    nixosConfigurations = genAttrs nixosHosts mkNixosHost // {
      pi = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = [
          ./pi/configuration.nix
          self.nixosModules.nixosBase
          self.sharedModules.base
          agenix.nixosModules.default
        ];
      };
    };

    darwinConfigurations = genAttrs darwinHosts mkDarwinHost;
  };
}
