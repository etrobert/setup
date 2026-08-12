{
  claude-code-wrapped,
  lib,
  writers,
}:
# The claude path is substituted in rather than put on PATH by a wrapper: this
# script is ours and calls exactly one binary, so a wrapper derivation would
# only add indirection.
writers.writePython3Bin "aichat-shim" { } (
  builtins.replaceStrings [ "@claude@" ] [ (lib.getExe claude-code-wrapped) ] (
    builtins.readFile ./shim.py
  )
)
