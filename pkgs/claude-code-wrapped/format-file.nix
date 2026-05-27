{
  black,
  fish,
  isort,
  nixfmt,
  prettier,
  rustfmt,
  shfmt,
  stylua,
  swiftformat,
  writeShellApplication,
}:
writeShellApplication {
  name = "format-file";
  runtimeInputs = [
    black
    fish
    isort
    nixfmt
    prettier
    rustfmt
    shfmt
    stylua
    swiftformat
  ];
  inheritPath = false;
  text = builtins.readFile ./format-file.sh;
}
