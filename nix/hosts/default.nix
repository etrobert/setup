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

  mkHost =
    {
      builder,
      homeModule,
      extraModules,
    }:
    host:
    builder {
      specialArgs = { inherit self pronto agenix; };
      modules = [
        ./${host}/configuration.nix
        { nixpkgs.overlays = [ neovim-nightly-overlay.overlays.default ]; }
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
    homeModule = ../modules/home/linux.nix;
    extraModules = [
      home-manager.nixosModules.home-manager
      agenix.nixosModules.default
      self.nixosModules.nixosWorkstation
      self.nixosModules.workstation
      self.nixosModules.nixosBase
      self.nixosModules.base
      self.nixosModules.unfree
    ];
  };

  mkDarwinHost = mkHost {
    builder = nix-darwin.lib.darwinSystem;
    homeModule = ../modules/home/darwin.nix;
    extraModules = [
      home-manager.darwinModules.home-manager
      agenix.darwinModules.default
      self.darwinModules.workstation
      self.darwinModules.base
      self.darwinModules.unfree
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
          self.nixosModules.base
          agenix.nixosModules.default
        ];
      };
    };

    darwinConfigurations = genAttrs darwinHosts mkDarwinHost;
  };
}
