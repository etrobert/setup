{ self, pkgs, ... }:
let
  inherit (self.nixosConfigurations.tower.config) ports;
in
{
  plugins = [
    {
      plugin = pkgs.vimPlugins.llama-vim;
      config = /* lua */ ''
        vim.g.llama_config = {
          endpoint_fim = "http://tower:${toString ports.llama-cpp}/infill",
          show_info = 0,
          -- The <leader>ll… defaults make every typed space wait timeoutlen in insert mode.
          keymap_fim_trigger = "",
          keymap_fim_accept_word = "",
        }
        vim.api.nvim_set_hl(0, "llama_hl_fim_hint", { link = "ComplHint" })
      '';
    }
  ];
}
