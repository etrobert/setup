# 200: https://code.claude.com/docs/en/memory
# 500: https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices
{ self, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      checks.agent-instructions-length = pkgs.runCommand "agent-instructions-length-check" { } /* bash */ ''
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
        check AGENTS.md 200
        check SKILL.md 500
        [ "$status" -eq 0 ] && touch $out
      '';
    };
}
