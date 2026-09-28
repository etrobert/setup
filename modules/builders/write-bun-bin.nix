_: {
  perSystem =
    { pkgs, lib, ... }:
    {
      writers.writeBunBin =
        name:
        {
          # A directory with the package.json and package-lock.json of the script's imports
          npmRoot ? null,
        }:
        pkgs.writers.makeScriptWriter {
          interpreter = lib.getExe pkgs.bun;
          # ":ts" maps the empty extension, which the script's /bin/<name> has.
          check = "${lib.getExe pkgs.bun} build --no-bundle --loader :ts";
          makeWrapperArgs = lib.optionals (npmRoot != null) [
            "--set"
            "NODE_PATH"
            "${
              pkgs.importNpmLock.buildNodeModules {
                inherit npmRoot;
                inherit (pkgs) nodejs;
              }
            }/node_modules"
          ];
        } "/bin/${name}";
    };
}
