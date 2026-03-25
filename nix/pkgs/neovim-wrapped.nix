{
  symlinkJoin,
  makeWrapper,
  neovim,
  lib,
  bash-language-server,
  black,
  gopls,
  imagemagick,
  isort,
  lua-language-server,
  nixd,
  nixfmt,
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
  postBuild = ''
    wrapProgram $out/bin/nvim \
      --prefix PATH : ${
        lib.makeBinPath [
          bash-language-server
          black # python formatter
          gopls
          imagemagick # for image rendering in nvim using snacks.image
          isort # python import sorter
          lua-language-server
          nixd
          nixfmt
          shfmt
          stylua
          tree-sitter
          typescript-language-server
          vscode-langservers-extracted
        ]
      }
  '';
}
