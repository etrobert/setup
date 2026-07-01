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
    # Pinned nixpkgs for darwin packages that fail to build on newer revs.
    # Update manually when upstream is fixed; excluded from automated updates.
    # Currently pins bitwarden-desktop, whose 2026.5.0 electron-builder step
    # fails on darwin with `spawn security ENOENT` (NixOS/nixpkgs#526914).
    nixpkgs-darwin-pins.url = "github:nixos/nixpkgs/64c08a7ca051951c8eae34e3e3cb1e202fe36786";
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
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    etiennerobert-com = {
      url = "github:etrobert/etiennerobert.com";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    creatures = {
      url = "github:etrobert/creatures";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    rift-radar = {
      url = "github:etrobert/rift-radar";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    rack = {
      url = "github:etrobert/rack";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Tracks the latest Claude Code release ahead of nixpkgs' packaging cadence
    # (hourly bot, official Anthropic binaries). `nix flake update` keeps it
    # current. Built against our own nixpkgs via the follows below.
    nix-claude-code = {
      url = "github:ryoppippi/nix-claude-code";
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
          ./modules/home/hypridle.nix
          ./modules/nix-index.nix
          ./modules/nixos-workstation.nix
          ./modules/workstation.nix
          ./modules/nixos-base.nix
          ./modules/base.nix
          ./modules/darwinModules.nix
          ./modules/unfree.nix
          ./modules/networkmanager.nix
          ./modules/file-manager.nix
          ./modules/pimsync.nix
          ./modules/lan-dns.nix
          ./modules/darkman.nix
          ./modules/mpd.nix
          ./modules/hypridle.nix
          ./modules/awww.nix
          ./modules/cachix-push.nix
          ./modules/copilot-api.nix
          ./modules/server.nix
          ./modules/ntfy.nix
          ./modules/homepage.nix
          ./modules/cockpit.nix
          ./modules/umami.nix
          ./modules/claude-warmup.nix
          ./modules/gaming.nix
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
                  "claude-code"
                  "cmp-emoji"
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
                  yamllint
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

              yamllint = pkgs.runCommand "yamllint-check" { nativeBuildInputs = [ pkgs.yamllint ]; } ''
                yamllint --strict ${self} && touch $out
              '';
            };

            formatter = pkgs.nixfmt-tree;
          };
      }
    );
}
