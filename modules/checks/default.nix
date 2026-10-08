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

      # nufmt's line_length doesn't cap every line yet: https://github.com/nushell/nufmt/issues/241
      nu-line-length = pkgs.runCommand "nu-line-length-check" { } ''
        cd ${self}
        long=$(find . -name '*.nu' -exec awk 'length > 100 { print FILENAME ":" FNR }' {} +)
        if [ -n "$long" ]; then
          echo "Nushell lines over 100 columns:"
          echo "$long"
          exit 1
        fi
        touch $out
      '';
    };
  };
}
