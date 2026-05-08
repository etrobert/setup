{ writers, python3Packages }:
writers.writePython3Bin "birthdays" {
  libraries = [ python3Packages.vobject ];
} (builtins.readFile ./birthdays.py)
