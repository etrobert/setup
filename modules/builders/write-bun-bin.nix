_: {
  perSystem =
    { pkgs, lib, ... }:
    {
      writers.writeBunBin =
        name:
        pkgs.writers.makeScriptWriter {
          interpreter = lib.getExe pkgs.bun;
          # ":ts" maps the empty extension, which the script's /bin/<name> has.
          check = "${lib.getExe pkgs.bun} build --no-bundle --loader :ts";
        } "/bin/${name}";
    };
}
