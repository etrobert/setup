{ pkgs, ... }:
{
  plugins = [
    {
      plugin = pkgs.vimPlugins.nvim-treesitter.withPlugins (
        p: with p; [
          bash
          caddy
          c
          diff
          git_config
          hyprlang
          html
          ini
          lua
          luadoc
          markdown
          markdown_inline
          nix
          toml
          query
          ssh_config
          vim
          vimdoc
          javascript
          typescript
          json
          go
          scheme
          rust
          zsh
        ]
      );
      luaConfig = builtins.readFile ./config.lua;
    }
    { plugin = pkgs.vimPlugins.nvim-treesitter-textobjects; }
  ];
}
