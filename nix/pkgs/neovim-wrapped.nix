{
  self',
  stdenv,
  runCommandLocal,
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
      gh # used by octo.lua
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
      bash # used by fugitive for cc
      cargo
      rust-analyzer
      rustc
      rustfmt
      shfmt
      stylua
      openssh # this is for :Git pull to be able to use ssh
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
  );
in
wrapNeovimUnstable neovim-unwrapped {
  plugins = [
    {
      plugin = vimPlugins.bufferline-nvim;
      config = /* vim */ ''
        lua require("bufferline").setup({ options = { diagnostics = "nvim_lsp", numbers = "buffer_id", show_buffer_close_icons = false } })
      '';
    }
  ];
  wrapperArgs = [
    "--set"
    "PATH"
    (lib.toString path)
  ];
}
