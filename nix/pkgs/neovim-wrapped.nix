{
  self',
  stdenv,
  symlinkJoin,
  makeWrapper,
  runCommandLocal,
  neovim,
  lib,
  bash-language-server,
  black,
  coreutils,
  curl,
  fd,
  git,
  gh,
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
  tree-sitter,
  tmux,
  typescript-language-server,
  vscode-langservers-extracted,
  wl-clipboard,
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
in
symlinkJoin {
  name = "neovim-wrapped";
  nativeBuildInputs = [ makeWrapper ];
  paths = [ neovim ];
  meta.mainProgram = "nvim";
  postBuild = ''
    wrapProgram $out/bin/nvim \
      --set PATH ${
        lib.makeBinPath (
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
            tree-sitter
            tmux # required by vim-tmux-navigator
            typescript-language-server
            vscode-langservers-extracted
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
        )
      }
  '';
}
