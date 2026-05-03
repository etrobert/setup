if exists("current_compiler")
  finish
endif
let current_compiler = "statix"

CompilerSet makeprg=statix\ check\ -o\ errfmt
CompilerSet errorformat=%f>%l:%c:%t:%n:%m
