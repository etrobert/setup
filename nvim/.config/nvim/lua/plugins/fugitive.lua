vim.pack.add({ "https://github.com/tpope/vim-fugitive" })
vim.cmd("packadd vim-fugitive")
vim.keymap.set("n", "<leader>ds", ":Gdiffsplit<CR>", { desc = "Git diff split" })