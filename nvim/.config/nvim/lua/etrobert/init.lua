require("etrobert.remap")
require("etrobert.set")

-- Show welcome screen when Neovim starts
local welcome = require("etrobert.welcome")
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    -- Only show welcome screen if no arguments were passed to Neovim
    if vim.fn.argc() == 0 then
      welcome.setup()
    end
  end,
})