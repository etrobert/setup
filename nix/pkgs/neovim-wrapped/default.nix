{
  pkgs,
  self',
  stdenv,
  runCommandLocal,
  callPackage,
  neovim-unwrapped,
  wrapNeovimUnstable,
  lib,
  bash,
  bash-language-server,
  coreutils,
  curl,
  fd,
  git,
  gh,
  ghostty,
  ghostty-bin,
  gnutar,
  gopls,
  gzip,
  imagemagick,
  lua-language-server,
  nixd,
  nixfmt,
  nodejs_24,
  ripgrep,
  cargo,
  rust-analyzer,
  rustc,
  stylua,
  openssh,
  tailwindcss-language-server,
  tree-sitter,
  tmux,
  typescript-language-server,
  vscode-langservers-extracted,
  wl-clipboard,
  vimPlugins,
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
      bash-language-server
      stdenv.cc # required by tree-sitter parser compilation
      curl # used in my config
      fd # used by telescope
      gnutar # used by treesitter
      gopls
      gzip # used by treesitter
      imagemagick # for image rendering in nvim using snacks.image
      lua-language-server
      nixd
      nixfmt
      nodejs_24 # used by copilot plugin
      ripgrep # used by telescope
      cargo
      rust-analyzer
      rustc
      tailwindcss-language-server
      tree-sitter
      typescript-language-server
      vscode-langservers-extracted
    ]
    ++ lib.optionals stdenv.isDarwin [
      pbcopy
      pbpaste
      ghostty-bin # used by snacks.image
    ]
    ++ lib.optionals stdenv.isLinux [
      wl-clipboard
      coreutils # provides cat for copying
      ghostty # used by snacks.image
    ]
    ++ (if with-git-wrapped then [ self'.packages.git-wrapped ] else [ git ])
    ++ (lib.concatMap (plugin: plugin.extraPackages) cfg.plugins)
  );
in
wrapNeovimUnstable neovim-unwrapped {
  plugins =
    with vimPlugins;
    [ snacks-nvim ] ++ map (plugin: { inherit (plugin) plugin config; }) cfg.plugins;
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
