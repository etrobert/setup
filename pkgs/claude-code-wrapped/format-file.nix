{
  black,
  isort,
  nixfmt,
  prettier,
  rustfmt,
  shfmt,
  stylua,
  writeShellApplication,
}:
writeShellApplication {
  name = "format-file";
  runtimeInputs = [
    black
    isort
    nixfmt
    prettier
    rustfmt
    shfmt
    stylua
  ];
  inheritPath = false;
  text = builtins.readFile ./format-file.sh;
}
