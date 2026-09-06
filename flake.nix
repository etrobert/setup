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

      inputs = {
        nixpkgs.follows = "nixpkgs";
        darwin.follows = "nix-darwin";
        home-manager.follows = "home-manager";
      };
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    tsnsrv = {
      url = "github:boinkor-net/tsnsrv";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    node-exporter-dashboard = {
      url = "file+https://grafana.com/api/dashboards/1860/revisions/latest/download";
      flake = false;
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    # Upstream's default branch is its dev branch; the moving `latest` tag
    # tracks stable releases and still follows `nix flake update`.
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";
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
    countdown = {
      url = "github:etrobert/countdown";
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
    dispatch = {
      url = "github:etrobert/dispatch";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nutricalc = {
      url = "github:Palomia/nutricalc";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    noctalia-official-plugins = {
      url = "github:noctalia-dev/official-plugins";
      flake = false;
    };
    noctalia-community-plugins = {
      url = "github:noctalia-dev/community-plugins";
      flake = false;
    };
    # Tracks the latest Claude Code release ahead of nixpkgs' packaging cadence
    # (hourly bot, official Anthropic binaries). `nix flake update` keeps it
    # current. Built against our own nixpkgs via the follows below.
    nix-claude-code = {
      url = "github:ryoppippi/nix-claude-code";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # The plugin behind figma@claude-plugins-official: Figma's remote MCP
    # server plus its design-to-code skills. Taken as an input rather than
    # installed with `claude plugin install`, which writes into a gitignored
    # cache and so does not reproduce on a new machine.
    figma-mcp-plugin = {
      url = "github:figma/mcp-server-guide";
      flake = false;
    };

    # Our fork, adding the `command` client: backed by a local command.
    aichat = {
      url = "github:etrobert/aichat/command-client";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    neovim-nightly.url = "github:nix-community/neovim-nightly-overlay";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    let
      inherit (inputs.nixpkgs) lib;

      # A `_` prefix marks a path that is not a flake module — a package's own
      # evalModules or callPackage tree. Same convention as vic/import-tree.
      importTree =
        path:
        lib.filter (file: !lib.hasInfix "/_" (toString file)) (
          lib.fileset.toList (lib.fileset.fileFilter (file: file.hasExt "nix") path)
        );
    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = importTree ./modules;

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

            overlays = [ inputs.neovim-nightly.overlays.default ];

            config.allowUnfreePredicate =
              pkg:
              builtins.elem (lib.getName pkg) [
                "claude-code"
                "copilot-language-server"
                "vscode"
                "vscode-extension-ms-vsliveshare-vsliveshare"
              ];
          };

          devShells.pimsync = pkgs.mkShell {
            packages = [
              (pkgs.python3.withPackages (ps: with ps; [ vobject ]))
            ];
          };

          formatter = pkgs.nixfmt-tree;
        };
    };
}
