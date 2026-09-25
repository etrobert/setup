# Under `legacyPackages.<system>.writers`, so `.#writers.writeNuBin` resolves
# here the same way `nixpkgs#writers.writeNuBin` resolves there.
#
# nixpkgs' writeNuBin accepts a `check` but, unlike its writeFish, defaults it
# to none — so a parse error builds clean and surfaces only when the script next
# runs, which for a timer means a notification that silently never arrives.
# nu-check parses without executing.
_: {
  perSystem =
    { pkgs, lib, ... }:
    {
      legacyPackages.writers.writeNuBin =
        name: args:
        pkgs.writers.writeNuBin name (
          args
          // {
            check = pkgs.writeShellScript "nu-check" ''
              set -e
              ${lib.getExe pkgs.nushell} --no-config-file --commands "nu-check --debug '$1'"
              ${lib.optionalString (args ? check) ''${args.check} "$1"''}
            '';
          }
        );
    };
}
