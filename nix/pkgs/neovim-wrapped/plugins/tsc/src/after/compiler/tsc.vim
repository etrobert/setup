" :help write-compiler-plugin

" We don't do the if exists guard here because
" We want to override makeprg but keep errorformat

let current_compiler = "tsc"

CompilerSet makeprg=bun\ tsc
