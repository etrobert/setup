{ pkgs }:
pkgs.symlinkJoin {
  name = "neovim-wrapped";
  buildInputs = [ pkgs.makeWrapper ];
  paths = [ pkgs.neovim ];
  postBuild = ''
    wrapProgram $out/bin/nvim \
      --prefix PATH : ${
        pkgs.lib.makeBinPath (
          with pkgs;
          [
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
        )
      }
  '';
}
