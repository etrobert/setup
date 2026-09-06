{
  black,
  isort,
  nixfmt,
  prettier,
  rustfmt,
  shfmt,
  stylua,
  taplo,
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
    taplo
  ];
  inheritPath = false;
  text = builtins.readFile ./format-file.sh;
}
