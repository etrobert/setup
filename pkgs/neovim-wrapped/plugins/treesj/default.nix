{ pkgs, ... }:
{
  plugins = [
    {
      plugin = pkgs.vimPlugins.treesj;
      config = /* lua */ ''
        require("treesj").setup({ max_join_length = 500 })
      '';
    }
  ];
}
