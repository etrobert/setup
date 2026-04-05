{ pkgs, ... }:
{
  plugins = [
    {
      plugin = pkgs.vimPlugins.vim-fugitive;
      luaConfig = /* lua */ ''
        vim.keymap.set("n", "<leader>ds", ":Gdiffsplit<CR>", { desc = "Git diff split" })
      '';
      extraPackages = with pkgs; [ bash ]; # used for cc
    }
  ];
}
