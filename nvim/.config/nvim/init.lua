require("etrobert")

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  { "nvim-telescope/telescope.nvim", dependencies = { 'nvim-lua/plenary.nvim' } },
  { "rose-pine/neovim", name = "rose-pine", init = function()
        vim.cmd('colorscheme rose-pine')
  end},
  { 'nvim-treesitter/nvim-treesitter', run = 'TSUpdate' },
  { 'tpope/vim-fugitive' },
  { 'lewis6991/gitsigns.nvim' },
  { 'stevearc/conform.nvim' },
  -- LSP Setup
  { 'VonHeikemen/lsp-zero.nvim' },
  { 'neovim/nvim-lspconfig' },
  { 'williamboman/mason.nvim' },
  { 'williamboman/mason-lspconfig.nvim' },
  { 'hrsh7th/nvim-cmp' },
  { 'hrsh7th/cmp-nvim-lsp' },
  { 'hrsh7th/cmp-buffer' },
  { 'hrsh7th/cmp-path' },
  { 'saadparwaiz1/cmp_luasnip' },
  { 'hrsh7th/cmp-nvim-lua' },
  { 'L3MON4D3/LuaSnip' },
  { 'rafamadriz/friendly-snippets' },
})
