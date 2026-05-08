{ pkgs, ... }:
{
  plugins = [
    {
      plugin = pkgs.vimPlugins.catppuccin-nvim;
      luaConfig = /* lua */ ''
        if os.getenv("COLORTERM") == "truecolor" then
        	-- Graphical session
        	require("catppuccin").setup({ float = { transparent = true, solid = false } })
        	vim.cmd("colorscheme catppuccin-macchiato")
        	-- else we're in a tty, using default theme
        end
      '';
    }
  ];
}
