{
  pkgs,
  self',
  stdenv,
  runCommandLocal,
  neovim-unwrapped,
  wrapNeovimUnstable,
  lib,
  bash-language-server,
  coreutils,
  curl,
  git,
  gnutar,
  gopls,
  gzip,
  lua-language-server,
  nixd,
  cargo,
  rust-analyzer,
  rustc,
  tailwindcss-language-server,
  tree-sitter,
  typescript-language-server,
  vscode-langservers-extracted,
  wl-clipboard,
  with-git-wrapped ? true,
}:
let
  cfg =
    (lib.evalModules {
      specialArgs = { inherit pkgs; };
      modules = [
        ./module.nix
        ./plugins/lualine
        ./plugins/octo
        ./plugins/fugitive
        ./plugins/fidget
        ./plugins/lazydev
        ./plugins/bufferline
        ./plugins/ts-autotag
        ./plugins/spider
        ./plugins/catppuccin
        ./plugins/treesj
        ./plugins/vim-tmux-navigator
        ./plugins/which-key
        ./plugins/notify
        ./plugins/conform
        ./plugins/telescope
        ./plugins/snacks
        ./plugins/copilot
        ./plugins/gitsigns
        # Disabled because this takes a monstrous amount of ressources
        # ./plugins/workspace-diagnostics
        ./plugins/lspconfig
      ];
    }).config;

  pbcopy = runCommandLocal "pbcopy" { } ''
    mkdir -p $out/bin
    ln -s /usr/bin/pbcopy $out/bin/pbcopy
  '';

  pbpaste = runCommandLocal "pbpaste" { } ''
    mkdir -p $out/bin
    ln -s /usr/bin/pbpaste $out/bin/pbpaste
  '';

  path = lib.makeBinPath (
    [
      stdenv.cc # required by tree-sitter parser compilation
      curl # used in my config
      gnutar # used by treesitter
      gzip # used by treesitter
      cargo
      rustc
      tree-sitter
    ]
    ++ lib.optionals stdenv.isDarwin [
      pbcopy
      pbpaste
    ]
    ++ lib.optionals stdenv.isLinux [
      wl-clipboard
      coreutils # provides cat for copying
    ]
    ++ (if with-git-wrapped then [ self'.packages.git-wrapped ] else [ git ])
    ++ (lib.concatMap (plugin: plugin.extraPackages) cfg.plugins)
  );
in
wrapNeovimUnstable neovim-unwrapped {
  plugins = map (plugin: { inherit (plugin) plugin config; }) cfg.plugins;
  # TODO: Make a non dev variant
  luaRcContent = /* lua */ ''
    dofile(vim.fn.stdpath("config") .. "/init.lua")
  '';
  wrapperArgs = [
    "--set"
    "PATH"
    (lib.toString path)
  ];
}
