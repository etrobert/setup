if exists("current_compiler")
  finish
endif
let current_compiler = "deadnix"

CompilerSet makeprg=deadnix-errfmt
CompilerSet errorformat=%f>%l:%c:%t:%n:%m
