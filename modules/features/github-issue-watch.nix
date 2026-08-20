{ self, ... }:
let
  issues = [
    {
      repo = "niri-wm/niri";
      number = 932;
      note = "Native pinned windows may have landed — drop the nirius follow-mode workaround (Mod+G) once the release reaches nixpkgs.";
    }
  ];
in
{
  flake.nixosModules.githubIssueWatch =
    { pkgs, lib, ... }:
    {
      systemd.services.github-issue-watch = {
        description = "Notify when a watched upstream GitHub issue closes";

        path = [
          pkgs.curl
          pkgs.jq
          self.packages.${pkgs.stdenv.hostPlatform.system}.ntfy-wrapped
        ];

        # ntfy-wrapped supplies the endpoint (NTFY_TOPIC); --quiet is silent
        # on success but still prints server errors.
        script =
          /* bash */ ''
            set -u -o pipefail

            check() {
              local repo="$1" number="$2" note="$3" issue state
              issue=$(curl --silent --fail --location "https://api.github.com/repos/$repo/issues/$number")
              state=$(jq --raw-output '.state' <<<"$issue")

              if [ "$state" = open ]; then
                return
              fi

              jq --raw-output --arg note "$note" \
                '"\(.title)\nClosed as \(.state_reason).\n\($note)\n\(.html_url)"' <<<"$issue" |
                ntfy publish --quiet --title "$repo#$number closed"
            }

          ''
          + lib.concatMapStrings (
            issue:
            "check ${
              lib.escapeShellArgs [
                issue.repo
                (toString issue.number)
                issue.note
              ]
            }\n"
          ) issues;

        serviceConfig.Type = "oneshot";
      };

      systemd.timers.github-issue-watch = {
        description = "Schedule the daily GitHub issue close check";
        wantedBy = [ "timers.target" ];

        timerConfig = {
          OnCalendar = "*-*-* 09:00:00";
          Persistent = true;
        };
      };
    };
}
