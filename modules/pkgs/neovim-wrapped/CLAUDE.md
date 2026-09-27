# neovim-wrapped

Every directory in `_plugins/` is a plugin, loaded unless listed in `disabled`
in `default.nix`.

The catch-all plugins take nothing else:

- `set` — vim options only (`vim.opt.*`, `vim.o.*`)
- `remap` — keymaps only (`vim.keymap.set`, `vim.api.nvim_create_user_command`)

New behavior (autocmds, etc.) belongs in its own dedicated plugin.
