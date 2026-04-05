{ pkgs, ... }:
{
  plugins = [
    {
      plugin = pkgs.vimPlugins.nvim-notify;
      luaConfig = /* lua */ ''
        require("notify").setup({ merge_duplicates = false, background_colour = "#25273A" })
        vim.notify = require("notify")
      '';
    }
  ];
}
