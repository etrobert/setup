{ pkgs, ... }:
{
  plugins = [
    {
      plugin = pkgs.vimPlugins.catppuccin-nvim;
      config = /* lua */ ''
        -- Use the truecolor colorscheme in any real terminal emulator; fall back
        -- to nvim's default theme in the Linux virtual console (TERM=linux),
        -- which has no truecolor or nerd-font glyphs.
        if os.getenv("TERM") ~= "linux" then
        	-- Enable truecolor explicitly: under tmux-256color (e.g. ssh from a
        	-- tmux session) nvim won't auto-detect it, so the theme would
        	-- otherwise render in approximated 256-color.
        	vim.opt.termguicolors = true
        	require("catppuccin").setup({ float = { transparent = true, solid = false } })
        	vim.cmd("colorscheme catppuccin-macchiato")
        end
      '';
    }
  ];
}
