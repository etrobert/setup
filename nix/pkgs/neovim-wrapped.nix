{
  stdenv,
  symlinkJoin,
  makeWrapper,
  runCommand,
  neovim,
  lib,
  bash-language-server,
  black,
  coreutils,
  curl,
  fd,
  gh,
  git,
  gopls,
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
}:
let
  pbcopy = runCommand "pbcopy" { } ''
    mkdir -p $out/bin
    ln -s /usr/bin/pbcopy $out/bin/pbcopy
  '';
in
symlinkJoin {
  name = "neovim-wrapped";
  buildInputs = [ makeWrapper ];
  paths = [ neovim ];
  meta.mainProgram = "nvim";
  postBuild = ''
    wrapProgram $out/bin/nvim \
      --set PATH ${
        lib.makeBinPath (
          [
            bash-language-server
            black # python formatter
            curl # used in my config
            fd # used by telescope
            gh # used by octo.lua
            git
            gopls
            imagemagick # for image rendering in nvim using snacks.image
            isort # python import sorter
            lua-language-server
            nixd
            nixfmt
            pbcopy
            prettierd
            ripgrep # used by telescope
            shfmt
            stylua
            tree-sitter
            tmux # required by vim-tmux-navigator
            typescript-language-server
            vscode-langservers-extracted
          ]
          ++ lib.optionals stdenv.isDarwin [ pbcopy ]
          ++ lib.optionals stdenv.isLinux [
            wl-clipboard
            coreutils # provides cat for copying
          ]
        )
      }
  '';
}
