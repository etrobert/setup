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
        	require("catppuccin").setup({ float = { transparent = true, solid = false } })
        	vim.cmd("colorscheme catppuccin-macchiato")
        end
      '';
    }
  ];
}
