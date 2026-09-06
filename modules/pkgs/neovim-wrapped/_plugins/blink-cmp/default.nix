{ pkgs, ... }:
{
  plugins = [
    {
      plugin = pkgs.vimPlugins.blink-cmp;
      config = /* lua */ ''
        require("blink.cmp").setup({
        	keymap = {
        		-- <Tab> belongs to inline completion, see plugins/remap
        		["<Tab>"] = false,
        		["<C-k>"] = false, -- i_CTRL-K, digraphs
        		["<C-l>"] = { "snippet_forward" },
        		["<C-h>"] = { "snippet_backward" },
        		-- the preset's fallback_to_mappings swallows i_CTRL-N/i_CTRL-P
        		["<C-n>"] = { "select_next", "fallback" },
        		["<C-p>"] = { "select_prev", "fallback" },
        	},
        	cmdline = { enabled = false },
        	completion = {
        		accept = { auto_brackets = { enabled = false } },
        		documentation = { auto_show = true },
        		list = { selection = { auto_insert = false } },
        	},
        	signature = { enabled = true },
        	sources = {
        		default = { "lsp", "path", "snippets", "emoji" },
        		providers = {
        			emoji = { module = "blink-emoji" },
        			snippets = { opts = { search_paths = { "${./snippets}" } } },
        		},
        	},
        })
      '';
    }
    { plugin = pkgs.vimPlugins.blink-emoji-nvim; }
    { plugin = pkgs.vimPlugins.friendly-snippets; }
  ];
}
