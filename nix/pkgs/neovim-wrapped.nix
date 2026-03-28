{
  symlinkJoin,
  makeWrapper,
  neovim,
  lib,
  bash-language-server,
  black,
  fd,
  gh,
  git,
  gopls,
  imagemagick,
  isort,
  lua-language-server,
  nixd,
  nixfmt,
  ripgrep,
  shfmt,
  stylua,
  tree-sitter,
  typescript-language-server,
  vscode-langservers-extracted,
}:
symlinkJoin {
  name = "neovim-wrapped";
  buildInputs = [ makeWrapper ];
  paths = [ neovim ];
  meta.mainProgram = "nvim";
  postBuild = ''
    wrapProgram $out/bin/nvim \
      --set PATH ${
        lib.makeBinPath [
          bash-language-server
          black # python formatter
          fd # used by telescope
          gh # used by octo.lua
          git
          gopls
          imagemagick # for image rendering in nvim using snacks.image
          isort # python import sorter
          lua-language-server
          nixd
          nixfmt
          ripgrep # used by telescope
          shfmt
          stylua
          tree-sitter
          typescript-language-server
          vscode-langservers-extracted
        ]
      }
  '';
}
