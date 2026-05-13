{ pkgs, ... }:
let
  words = [
    "Étienne"
    "Maïlys"
    "Tanzfabrik"
  ];

  wordFile = pkgs.writeText "nvim-spell-words" (builtins.concatStringsSep "\n" words);

  spellPkg =
    pkgs.runCommand "nvim-spell-custom"
      {
        nativeBuildInputs = [ pkgs.neovim-unwrapped ];
      }
      ''
        mkdir -p $out/spell
        HOME=$(mktemp -d) nvim --headless --clean \
          -c "mkspell $out/spell/custom ${wordFile}" \
          -c "qa!"
      '';
in
{
  plugins = [
    {
      plugin = spellPkg;
      luaConfig = /* lua */ ''
        vim.opt.spelllang = "en,custom"
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
