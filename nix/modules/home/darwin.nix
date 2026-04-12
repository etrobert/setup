{ self, ... }:
{
  flake.homeModules.darwin =
    { config, ... }:
    {
      imports = [ self.homeModules.common ];

      home = {
        homeDirectory = "/Users/${config.home.username}";

        file.".hushlogin".text = "";

        file.".config/raycast/scripts/meet.sh" = {
          executable = true;
          text = ''
            #!/usr/bin/env bash

            # @raycast.schemaVersion 1
            # @raycast.title New Google Meet
            # @raycast.mode silent
            # @raycast.icon 📹
            # @raycast.author Étienne Robert
            # @raycast.authorURL https://github.com/etrobert

            open https://meet.google.com/new
          '';
        };

        file.".config/raycast/scripts/git-standup.sh" = {
          executable = true;
          text = ''
            #!/usr/bin/env bash

            # Required parameters:
            # @raycast.schemaVersion 1
            # @raycast.title Standup
            # @raycast.mode fullOutput

            # Optional parameters:
            # @raycast.icon 💻

            # Documentation:
            # @raycast.author Étienne Robert
            # @raycast.authorURL https://github.com/etrobert
            # @raycast.description Lists your commits from the last 24 hours.

            cd "${config.home.homeDirectory}/work/banani-web-main" || exit 1

            # On Monday, show commits since Friday; otherwise since yesterday
            if [ "$(date +%u)" -eq 1 ]; then
              SINCE="last friday"
            else
              SINCE="yesterday.midnight"
            fi

            git log \
              --all \
              --author="$(git config user.name)" \
              --since="$SINCE" \
              --pretty=format:"%C(yellow)%d%Creset %s %Cblue(%ar)%Creset"
          '';
        };

        shellAliases = {
          bg = "open /Volumes/T7/Applications/Baldur\'s\ Gate\ 3.app/Contents/MacOS/Baldur\'s\ Gate\ 3\ GOG";
        };
      };

      services.syncthing = {
        enable = true;
        guiAddress = "0.0.0.0:8384";
        settings = import ../../syncthing-settings.nix { dataDir = config.home.homeDirectory; };
      };
    };
}
