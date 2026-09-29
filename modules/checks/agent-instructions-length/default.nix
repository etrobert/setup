# 200 lines: https://code.claude.com/docs/en/memory
# 500 lines: https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices
# Non-blank lines: deleting blank lines doesn't shrink the content
# 3/4 of those limits: our Markdown is ~75% non-blank lines
{ self, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      checks.agent-instructions-length = pkgs.runCommand "agent-instructions-length-check" { } /* bash */ ''
        status=0
        check() {
          for file in $(find ${self} -name "$1"); do
            lines=$(grep --count . "$file")
            if [ "$lines" -gt "$2" ]; then
              echo "''${file#${self}/}: $lines non-blank lines, limit $2"
              status=1
            fi
          done
        }
        check CLAUDE.md 150
        check AGENTS.md 150
        check SKILL.md 375
        [ "$status" -eq 0 ] && touch $out
      '';
    };
}
