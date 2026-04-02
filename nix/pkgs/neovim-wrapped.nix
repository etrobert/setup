{
  self',
  stdenv,
  symlinkJoin,
  makeWrapper,
  runCommandLocal,
  neovim-unwrapped,
  lib,
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
  prettierd,
  ripgrep,
  shfmt,
  stylua,
  tailwindcss-language-server,
  tree-sitter,
  tmux,
  typescript-language-server,
  vscode-langservers-extracted,
  wl-clipboard,
  with-git-wrapped ? true,
  fetchFromGitHub,
  wrapNeovim,
}:
let
  neovim-pinned = wrapNeovim (neovim-unwrapped.overrideAttrs (_old: {
    version = "0.12.0";
    src = fetchFromGitHub {
      owner = "neovim";
      repo = "neovim";
      rev = "v0.12.0";
      hash = "sha256-uWhrGAwQ2nnAkyJ46qGkYxJ5K1jtyUIQOAVu3yTlquk=";
    };
  })) { };

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
      prettierd
      ripgrep # used by telescope
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
  );
in
symlinkJoin {
  name = "neovim-wrapped";
  nativeBuildInputs = [ makeWrapper ];
  paths = [ neovim-pinned ];
  meta.mainProgram = "nvim";
  postBuild = ''
    wrapProgram $out/bin/nvim \
      --set PATH ${path}
  '';
}
