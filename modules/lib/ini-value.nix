{ lib, ... }:
{
  # The first `key=` line of an INI file, whatever its section.
  flake.lib.iniValue =
    file: key:
    lib.removePrefix "${key}=" (
      lib.findFirst (lib.hasPrefix "${key}=") (throw "no ${key}= in ${file}") (
        lib.splitString "\n" (builtins.readFile file)
      )
    );
}
