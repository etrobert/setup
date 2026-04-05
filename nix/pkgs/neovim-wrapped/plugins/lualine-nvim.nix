{ vimPlugins }:
{
  plugins = [
    {
      plugin = vimPlugins.lualine-nvim;
      luaConfig = /* lua */ ''
        local relative_path = { "filename", path = 1 }
        require("lualine").setup({
        	sections = { lualine_c = { relative_path }, lualine_x = { "filetype" } },
        	inactive_sections = { lualine_c = { relative_path } },
        })
      '';
    }
  ];
}
