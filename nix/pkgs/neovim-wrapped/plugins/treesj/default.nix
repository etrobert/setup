{ pkgs, ... }:
{
  plugins = [
    {
      plugin = pkgs.vimPlugins.treesj;
      luaConfig = /* lua */ ''
        require("treesj").setup({ max_join_length = 500 })
      '';
    }
  ];
}
