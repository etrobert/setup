# Bun runs any file as TypeScript, but `bun build` parses it as TypeScript
# only under a .ts name.
_: {
  perSystem =
    { pkgs, lib, ... }:
    {
      writers.writeBunBin =
        name:
        pkgs.writers.makeScriptWriter {
          interpreter = lib.getExe pkgs.bun;
          check = pkgs.writeShellScript "bun-check" ''
            cp "$1" "$TMPDIR/script.ts"
            ${lib.getExe pkgs.bun} build --no-bundle "$TMPDIR/script.ts" > /dev/null
          '';
        } "/bin/${name}";
    };
}
