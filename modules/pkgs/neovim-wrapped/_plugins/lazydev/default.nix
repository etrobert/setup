{ pkgs, ... }:
{
  plugins = [
    {
      plugin = pkgs.vimPlugins.lazydev-nvim;
      config = /* lua */ ''
        require("lazydev").setup({
        	library = { { path = "''${3rd}/luv/library", words = { "vim%.uv" } } },
        })

        require("blink.cmp").add_source_provider("lazydev", {
        	module = "lazydev.integrations.blink",
        	-- lua_ls also answers inside require(), so outrank it
        	score_offset = 100,
        })
        require("blink.cmp").add_filetype_source("lua", "lazydev")
      '';
    }
  ];
}
