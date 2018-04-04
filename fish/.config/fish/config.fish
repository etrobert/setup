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
