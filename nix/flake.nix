{
  # Substituters used when building this flake on a machine that has not yet
  # activated this config (e.g. CI, fresh installs, new machines). On machines
  # that have already activated this config, nix.settings takes over instead.
  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://soft-nix.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "soft-nix.cachix.org-1:/e6Y6fH2WAyIFK+F7+8bXTF4KdO4eRa4ed/d46Ytrxs="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
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
          inputs.home-manager.flakeModules.home-manager
          ./modules/hosts/tower
          ./modules/hosts/aaron
          ./modules/hosts/leod
          ./modules/hosts/pi
          ./modules/home
          ./modules/home/linux.nix
          ./modules/home/common.nix
          ./modules/home/darwin.nix
          ./modules/nixos-workstation.nix
          ./modules/workstation.nix
          ./modules/nixos-base.nix
          ./modules/base.nix
          ./modules/darwinModules.nix
          ./modules/unfree.nix
          ./modules/networkmanager.nix
          ./modules/pimsync.nix
          ./modules/darkman.nix
          ./pkgs
        ];

        systems = [
          "x86_64-linux"
          "aarch64-linux"
          "aarch64-darwin"
        ];

        perSystem =
          {
            pkgs,
            system,
            lib,
            ...
          }:
          {
            _module.args.pkgs = import inputs.nixpkgs {
              inherit system;
              config.allowUnfreePredicate =
                pkg:
                builtins.elem (lib.getName pkg) [
                  "copilot.vim"
                  "vscode"
                  "vscode-extension-ms-vsliveshare-vsliveshare"
                ];
            };

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
