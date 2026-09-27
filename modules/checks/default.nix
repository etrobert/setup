{ self, ... }: {
  perSystem = { pkgs, ... }: {
    checks = {
      statix = pkgs.runCommand "statix-check" { nativeBuildInputs = [ pkgs.statix ]; } ''
        statix check ${self} && touch $out
      '';

      deadnix = pkgs.runCommand "deadnix-check" { nativeBuildInputs = [ pkgs.deadnix ]; } ''
        deadnix --fail ${self} && touch $out
      '';

      yamllint = pkgs.runCommand "yamllint-check" { nativeBuildInputs = [ pkgs.yamllint ]; } ''
        yamllint --strict ${self} && touch $out
      '';

      stylua = pkgs.runCommand "stylua-check" { nativeBuildInputs = [ pkgs.stylua ]; } ''
        stylua --check ${self} && touch $out
      '';

      actionlint = pkgs.runCommand "actionlint-check" { nativeBuildInputs = [ pkgs.actionlint ]; } ''
        actionlint ${self}/.github/workflows/*.yml && touch $out
      '';

      # Bare nvim, not neovim-wrapped: a plugin's tests should fail on the
      # plugin, not on the rest of the config.
      neovim-plugins = pkgs.runCommand "neovim-plugins-check" { nativeBuildInputs = [ pkgs.neovim ]; } ''
        plugins=${self}/modules/pkgs/neovim-wrapped/_plugins
        for test in $plugins/*/test.lua; do
          echo "== $(basename $(dirname $test))"
          nvim --headless -u NONE \
            --cmd "set rtp+=${self}/modules/pkgs/neovim-wrapped/tests" \
            --cmd "set rtp+=$(dirname $test)/src" \
            -l $test
        done
        touch $out
      '';

      # Fails once upstream adds `sh` to ast_grep.filetypes, making the
      # override in neovim-wrapped's lspconfig plugin dead weight.
      lspconfig-ast-grep-filetypes = pkgs.runCommand "lspconfig-ast-grep-filetypes-check" { } ''
        ! grep --quiet "'sh'," ${pkgs.vimPlugins.nvim-lspconfig}/lsp/ast_grep.lua && touch $out
      '';
    };
  };
}
