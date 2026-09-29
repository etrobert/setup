# 200 lines: https://code.claude.com/docs/en/memory
# 500 lines: https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices
# Non-blank lines: deleting blank lines doesn't shrink the content
# 80% of those limits: our Markdown is at most 80% non-blank lines
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
        check CLAUDE.md 160
        check AGENTS.md 160
        check SKILL.md 400
        [ "$status" -eq 0 ] && touch $out
      '';
    };
}
