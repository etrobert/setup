{ pkgs, ... }:
let
  spellPkg =
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
in
{
  plugins = [
    {
      plugin = spellPkg;
      luaConfig = /* lua */ ''
        vim.opt.spelllang = "en,custom"
        vim.opt.spellfile = vim.fn.expand("~/setup/pkgs/neovim-wrapped/plugins/spell/words.add")
        vim.api.nvim_create_autocmd("FileType", {
          pattern = { "markdown", "gitcommit", "text" },
          callback = function()
            vim.opt_local.spell = true
          end,
        })
      '';
    }
  ];
}
