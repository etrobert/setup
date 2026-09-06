if exists("current_compiler")
  finish
endif
let current_compiler = "nix-check"

CompilerSet makeprg=nix-check-errfmt
CompilerSet errorformat=%f>%l:%c:%t:%n:%m
