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

      # 200: https://code.claude.com/docs/en/memory
      # 500: https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices
      doc-length = pkgs.runCommand "doc-length-check" { } /* bash */ ''
        status=0
        check() {
          for file in $(find ${self} -name "$1"); do
            lines=$(wc --lines < "$file")
            if [ "$lines" -gt "$2" ]; then
              echo "''${file#${self}/}: $lines lines, limit $2"
              status=1
            fi
          done
        }
        check CLAUDE.md 200
        check SKILL.md 500
        [ "$status" -eq 0 ] && touch $out
      '';
    };
  };
}
