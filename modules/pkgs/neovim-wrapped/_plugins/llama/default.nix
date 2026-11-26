{ self, pkgs, ... }:
let
  inherit (self.nixosConfigurations.tower.config) ports;
in
{
  plugins = [
    {
      plugin = pkgs.vimPlugins.llama-vim;
      config = /* lua */ ''
        vim.g.llama_config = { endpoint_fim = "http://tower:${toString ports.llama-cpp}/infill" }
      '';
    }
  ];
}
