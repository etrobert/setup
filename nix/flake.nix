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
    flake-parts.url = "github:hercules-ci/flake-parts";
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
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } (
      { self, ... }:
      {
        imports = [
          ./hosts
          ./hosts/tower
          ./hosts/aaron
          ./hosts/leod
          ./hosts/pi
          ./modules/home
          ./modules/nixos-workstation.nix
          ./modules/workstation.nix
          ./modules/nixos-base.nix
          ./modules/base.nix
          ./modules/darwinModules.nix
          ./modules/unfree.nix
          ./pkgs
        ];

        systems = [
          "x86_64-linux"
          "aarch64-linux"
          "aarch64-darwin"
        ];

        perSystem =
          { system, ... }:
          let
            pkgs = import inputs.nixpkgs {
              inherit system;
              overlays = [ inputs.neovim-nightly-overlay.overlays.default ];
            };
          in
          {
            _module.args.pkgs = pkgs;

            devShells = {
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
            };

            checks = {
              statix = pkgs.runCommand "statix-check" { nativeBuildInputs = [ pkgs.statix ]; } ''
                statix check ${self} && touch $out
              '';

              deadnix = pkgs.runCommand "deadnix-check" { nativeBuildInputs = [ pkgs.deadnix ]; } ''
                deadnix --fail ${self} && touch $out
              '';
            };

            formatter = pkgs.nixfmt;
          };
      }
    );
}
