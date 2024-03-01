local builtin = require('telescope.builtin')

-- Source: https://github.com/nvim-telescope/telescope.nvim/issues/855
require("telescope").setup {
    pickers = {
        live_grep = {
            file_ignore_patterns = {'.git'},
            additional_args = {'--hidden'}
        }
    }
}

vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})
vim.keymap.set('n', '<C-p>', builtin.git_files, {})