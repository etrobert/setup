{
  claude-code-wrapped,
  writers,
  wrapPackage,
}:
wrapPackage {
  package = writers.writePython3Bin "aichat-shim" { } (builtins.readFile ./shim.py);
  runtimeInputs = [ claude-code-wrapped ];
}
