{ pkgs, ... }:
{
  plugins = [
    {
      plugin = pkgs.vimPlugins.catppuccin-nvim;
      config = /* lua */ ''
        -- Use the full truecolor colorscheme in any real terminal emulator. Fall
        -- back to the default theme only in the Linux virtual console
        -- (TERM=linux), which can't do truecolor or nerd-font glyphs. We can't
        -- gate on COLORTERM because ssh doesn't forward it (SendEnv is only
        -- LANG/LC_*), so it's empty on remote hosts even from a truecolor
        -- terminal. termguicolors must be set explicitly: nvim only auto-enables
        -- it when COLORTERM=truecolor, which we no longer rely on.
        if os.getenv("TERM") ~= "linux" then
        	vim.opt.termguicolors = true
        	require("catppuccin").setup({ float = { transparent = true, solid = false } })
        	vim.cmd("colorscheme catppuccin-macchiato")
        end
      '';
    }
  ];
}
