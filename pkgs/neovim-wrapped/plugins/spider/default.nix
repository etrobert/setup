{ pkgs, ... }:
{
  plugins = [
    {
      plugin = pkgs.vimPlugins.nvim-spider;
      luaConfig = /* lua */ ''
        require("spider").setup({ skipInsignificantPunctuation = false })

        vim.keymap.set({ "n", "o", "x" }, "w", "<cmd>lua require('spider').motion('w')<CR>")
        vim.keymap.set({ "n", "o", "x" }, "e", "<cmd>lua require('spider').motion('e')<CR>")
        vim.keymap.set({ "n", "o", "x" }, "b", "<cmd>lua require('spider').motion('b')<CR>")
      '';
    }
  ];
}
