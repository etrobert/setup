{
  claude-code-wrapped,
  writers,
  wrapPackage,
}:
wrapPackage {
  # black (via the format-file hook) wraps at 88, writePython3Bin's flake8 at 79.
  # Let black own line length — the standard black+flake8 pairing.
  package = writers.writePython3Bin "aichat-shim" {
    flakeIgnore = [ "E501" ];
  } (builtins.readFile ./shim.py);
  runtimeInputs = [ claude-code-wrapped ];
}
