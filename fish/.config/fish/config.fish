# As of fish 2.2.0, the . command is deprecated and source should be used instead.
function sourceifexists --argument-names file --description 'sources arg if exists'
  if test -e $file
    . $file
  end
end

function fish_greeting
end

sourceifexists ~/.alias

switch (uname)
    case Linux
            sourceifexists ~/.alias.linux
    case Darwin
            sourceifexists ~/.alias.darwin
    case '*'
end

alias mkls="make 2> /tmp/mkls_tmp; or less /tmp/mkls_tmp"

# Workaround for fish autocomplete bug
# https://github.com/fish-shell/fish-shell/issues/952
function x86
    echo '(x86)'
end
function X86
    echo '(X86)'
end
