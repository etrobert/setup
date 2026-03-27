_: {
  flake.homeModules.common =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      symlink = path: config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/setup/${path}";
    in
    {
      home = {
        username = "soft";

        file = {
          ".config/home-manager".source = symlink "nix";

          ".prettierrc".text = builtins.toJSON { proseWrap = "always"; };

          ".profile".source = ../../../profile/.profile;

          ".gitconfig".source = ../../../git/.gitconfig;

          ".config/tmux/tmux.conf".source = ../../../tmux/.config/tmux/tmux.conf;

          ".config/nvim".source = symlink "nvim/.config/nvim";

          ".config/ghostty/config".source = symlink "ghostty/.config/ghostty/config";
        };

        sessionVariablesExtra = ''
          export OPENAI_API_KEY="$(cat /run/agenix/openai-api-key)"
          export GEMINI_API_KEY="$(cat /run/agenix/gemini-api-key)"
        '';

        # This value determines the Home Manager release that your
        # configuration is compatible with. This helps avoid breakage
        # when a new Home Manager release introduces backwards
        # incompatible changes.
        #
        # You can update Home Manager without changing this value. See
        # the Home Manager release notes for a list of state version
        # changes in each release.
        stateVersion = "25.11";
      };

      programs = {
        firefox = {
          enable = true;
          nativeMessagingHosts = lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.firefoxpwa ];
          policies = {
            PasswordManagerEnabled = false;
            SearchEngines = {
              Default = "DuckDuckGo";
            };
            ExtensionSettings = {
              "uBlock0@raymondhill.net" = {
                install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
                installation_mode = "force_installed";
                default_area = "menupanel";
              };
              "{446900e4-71c2-419f-a6a7-df9c091e268b}" = {
                install_url = "https://addons.mozilla.org/firefox/downloads/latest/bitwarden-password-manager/latest.xpi";
                installation_mode = "force_installed";
                default_area = "navbar";
              };
              "{d7742d87-e61d-4b78-b8a1-b469842139fa}" = {
                install_url = "https://addons.mozilla.org/firefox/downloads/latest/vimium-ff/latest.xpi";
                installation_mode = "force_installed";
                default_area = "menupanel";
              };
            };
          };
          profiles.default = {
            settings = {
              # Enable the new sidebar + vertical tabs via user prefs (policies block these).
              "sidebar.revamp" = true;
              "sidebar.verticalTabs" = true;
              "browser.ctrlTab.sortByRecentlyUsed" = true;
              "media.videocontrols.picture-in-picture.enable-when-switching-tabs.enabled" = true;
            };
          };
        };

        zsh = {
          enable = true;
          enableCompletion = false;
          autosuggestion.enable = true;
          syntaxHighlighting.enable = true;
          defaultKeymap = "viins";

          history = {
            size = 999999999;
            save = 999999999;
            path = "$HOME/.zsh_history";
            append = true;
          };

          setOptions = [
            "INTERACTIVE_COMMENTS"
            "PROMPT_SUBST"
          ];

          profileExtra = ''
            emulate sh
            . ~/.profile
            emulate zsh
          '';

          initContent = ''
            export CMD_TIMER_MS=

            preexec() {
              if [[ -z $CMD_TIMER_MS ]]; then
                CMD_TIMER_MS=$(date +%s%3N)
              fi
            }

            precmd() {
              if [[ -z $CMD_TIMER_MS ]]; then
                return
              fi

              local now
              now=$(date +%s%3N)
              export LAST_CMD_TIME=$((now - CMD_TIMER_MS))
              unset CMD_TIMER_MS
            }

            # needed over enableCompletion = true; to avoid errors on mac
            autoload -Uz compinit && compinit -i

            PS1='$(pronto $? --zsh)'
            RPROMPT='$(pronto $? --rprompt --zsh)'

            autoload -Uz edit-command-line
            zle -N edit-command-line
            bindkey "^F" edit-command-line

            bindkey '^?' backward-delete-char
            bindkey '^H' backward-delete-char

            # Override vi mode defaults: Ctrl-P/N for history search
            bindkey "^P" up-line-or-search
            bindkey "^N" down-line-or-search

            bindkey "^A" beginning-of-line
            bindkey "^E" end-of-line

            bindkey "^Y" autosuggest-accept
          '';
        };

        fzf.enable = true;
      };

      home.shellAliases = {
        grep = "grep --color=auto";

        # Ask for confirmation before overriding
        mv = "mv --interactive";
        cp = "cp --interactive";

        # Create dirs recursively and verbosely
        mkdir = "mkdir --parents --verbose";

        LS = "ls";
        sl = "ls";
        SL = "ls";

        # Using GNU ls from coreutils on both Linux and Darwin
        ls = "ls --classify --human-readable --color";

        gti = "git";
        gi = "git";

        make = "make -j8";
        watch = "watch --interval=1";

        rscp = "rsync -p --progress";

        only-unique = "sort | uniq";

        tmuxn = ''tmux new-session -A -s "$(basename "$(pwd)")" -e TMUX_SESSION_PATH="$(pwd)"'';
        ts = "tmux-sessionizer";
        tcd = "cd \"$TMUX_SESSION_PATH\"";

        # One-letter aliases for most used commands
        g = "git";
        t = "tmux";
        v = "nvim";

        # tree="tree -CF --dirsfirst"
        tree = "eza --tree --icons --group-directories-first --git-ignore";
        ltree = "tree --icons=always --color=always | less --raw-control-chars";

        font = "ghostty +show-face --string=Hello --style=regular";

        duf = "du -sh * .* | sort -h";

        server = "python3 -m http.server 8000";

        fhistory = "history | sed -E 's/^ +[0-9]+ +//' | fzf --tac --no-sort";

        agenix-rekey = "sudo agenix --rekey -i /etc/ssh/ssh_host_ed25519_key";

        music-dl = "yt-dlp --embed-thumbnail --extract-audio"; # --embed-metadata
      };

      # Let Home Manager install and manage itself.
      programs.home-manager.enable = true;
    };
}
