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
  black,
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
  isort,
  lua-language-server,
  nixd,
  nixfmt,
  nodejs_24,
  prettierd,
  ripgrep,
  cargo,
  rust-analyzer,
  rustc,
  rustfmt,
  shfmt,
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
      black # python formatter
      stdenv.cc # required by tree-sitter parser compilation
      curl # used in my config
      fd # used by telescope
      gnutar # used by treesitter
      gopls
      gzip # used by treesitter
      imagemagick # for image rendering in nvim using snacks.image
      isort # python import sorter
      lua-language-server
      nixd
      nixfmt
      nodejs_24 # used by copilot plugin
      prettierd
      ripgrep # used by telescope
      cargo
      rust-analyzer
      rustc
      rustfmt
      shfmt
      stylua
      tailwindcss-language-server
      tree-sitter
      tmux # required by vim-tmux-navigator
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
    [
      {
        plugin = bufferline-nvim;
        config = /* vim */ ''
          lua << EOF
            require("bufferline").setup({
              options = { diagnostics = "nvim_lsp", numbers = "buffer_id", show_buffer_close_icons = false }
            })
          EOF
        '';
      }
      catppuccin-nvim
      nvim-notify
      treesj
      snacks-nvim
      {
        plugin = nvim-ts-autotag;
        config = /* vim */ ''
          lua << EOF
            require("nvim-ts-autotag").setup({
            	opts = { enable_close = false, enable_rename = true, enable_close_on_slash = false },
            })
          EOF'';
      }
      which-key-nvim
      {
        plugin = lazydev-nvim;
        config = /* vim */ ''
          lua << EOF
            require("lazydev").setup({
            	library = { { path = "''${3rd}/luv/library", words = { "vim%.uv" } } },
            })
          EOF
        '';
      }
      {
        plugin = nvim-spider;
        config = /* vim */ ''lua require("spider").setup({ skipInsignificantPunctuation = false })'';
      }
      nvim-web-devicons
    ]
    ++ map (plugin: { inherit (plugin) plugin config; }) cfg.plugins;
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
