# Under `legacyPackages.<system>.writers`, so `.#writers.writeNuBin` resolves
# here the same way `nixpkgs#writers.writeNuBin` resolves there.
_: {
  perSystem =
    { pkgs, lib, ... }:
    {
      legacyPackages.writers = {
        # nixpkgs' writeNuBin accepts a `check` but, unlike its writeFish, defaults it
        # to none — so a parse error builds clean and surfaces only when the script next
        # runs, which for a timer means a notification that silently never arrives.
        # nu-check parses without executing.
        writeNuBin =
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

        # Bun runs any file as TypeScript, but `bun build` parses it as TypeScript
        # only under a .ts name.
        writeBunBin =
          name:
          pkgs.writers.makeScriptWriter {
            interpreter = lib.getExe pkgs.bun;
            check = pkgs.writeShellScript "bun-check" ''
              cp "$1" "$TMPDIR/script.ts"
              ${lib.getExe pkgs.bun} build --no-bundle "$TMPDIR/script.ts" > /dev/null
            '';
          } "/bin/${name}";
      };
    };
}
