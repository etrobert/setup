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
        # plenary ends every line with CR, which `nix build -L` renders as blank
        # lines. Exit status survives the pipe via stdenv's `set -o pipefail`.
        for spec in ${self}/modules/pkgs/neovim-wrapped/_plugins/*/tests/*_spec.lua; do
          echo "== $spec"
          nvim --headless -u NONE -n \
            --cmd "set rtp+=${pkgs.vimPlugins.plenary-nvim}" \
            --cmd "set rtp+=$(dirname $(dirname $spec))/src" \
            -c "lua require('plenary.busted').run('$spec')" 2>&1 | tr -d '\r'
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
