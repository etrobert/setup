if [[ $(uname) == 'Linux' ]]; then
  alias open='xdg-open'
  alias bt="bluetoothctl devices | fzf --with-nth=3.. | cut -d' ' -f2 | xargs bluetoothctl connect"
  alias home-assistant="docker run -d --name homeassistant -e TZ=\"Europe/Berlin\" -v ~/.config/home-assistant:/config --network=host ghcr.io/home-assistant/home-assistant:stable"
fi

alias grep='grep --color=auto'

# Ask for confirmation before overriding
alias mv='mv --interactive'
alias cp='cp --interactive'

# Create dirs recursively and verbosely
alias mkdir='mkdir --parents --verbose'

alias LS='ls'
alias sl='ls'
alias SL='ls'

# Using GNU ls from coreutils on both Linux and Darwin
alias ls='ls --classify --human-readable --color'

alias gti='git'
alias gi='git'

alias make='make -j8'
alias watch='watch --interval=1'

alias rscp='rsync -p --progress'

alias only-unique='sort | uniq'

alias tmuxn='tmux new-session -A -s "$(basename "$(pwd)")" -e TMUX_SESSION_PATH="$(pwd)"'
alias tcd='cd "$TMUX_SESSION_PATH"'

# One-letter aliases for most used commands
alias g="git"
alias t="tmux"
alias v="nvim"

# tree="tree -CF --dirsfirst"
alias tree="eza --tree --icons --group-directories-first --git-ignore"
alias ltree="tree --icons=always --color=always | less --raw-control-chars"

alias font="ghostty +show-face --string=Hello --style=regular"

alias duf="du -sh * .* | sort -h"

alias server="python3 -m http.server 8000"

alias fhistory="history | sed -E 's/^ +[0-9]+ +//' | fzf --tac --no-sort"

alias agenix-rekey="sudo agenix --rekey -i /etc/ssh/ssh_host_ed25519_key"

alias music-dl="yt-dlp --embed-thumbnail --extract-audio" # --embed-metadata
