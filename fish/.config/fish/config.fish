# As of fish 2.2.0, the . command is deprecated and source should be used instead.
if test -e ~/.alias
    . ~/.alias
end

alias mkls="make 2> tmp; or less tmp"
