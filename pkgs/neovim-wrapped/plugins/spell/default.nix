{ pkgs, ... }:
let
  customSpell =
    pkgs.runCommand "nvim-spell-custom"
      {
        nativeBuildInputs = [ pkgs.neovim-unwrapped ];
      }
      ''
        mkdir -p $out/spell
        HOME=$(mktemp -d) nvim --headless --clean \
          -c "mkspell $out/spell/custom ${./words.add}" \
          -c "qa!"
      '';

  frSpl = pkgs.fetchurl {
    url = "https://ftp.nluug.nl/pub/vim/runtime/spell/fr.utf-8.spl";
    hash = "sha256-q/uXArmNiHwXWs5Y8as5cz3AjQO2dNkU9WNE74bmO2E=";
  };

  frSpell = pkgs.runCommand "nvim-spell-fr" { } ''
    mkdir -p $out/spell
    cp ${frSpl} $out/spell/fr.utf-8.spl
  '';
in
{
  plugins = [
    {
      plugin = customSpell;
      config = /* lua */ ''
        vim.opt.spelllang = "en,fr,custom"
        vim.opt.spellfile = vim.fn.expand("~/setup/pkgs/neovim-wrapped/plugins/spell/words.add")
        vim.api.nvim_create_autocmd("FileType", {
          pattern = { "markdown", "gitcommit", "text" },
          callback = function()
            vim.opt_local.spell = true
          end,
        })
      '';
    }
    { plugin = frSpell; }
  ];
}
