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
        script:
        let
          nodeModules = pkgs.importNpmLock.buildNodeModules {
            inherit npmRoot;
            inherit (pkgs) nodejs;
          };
          # Fails the build on a syntax error or an unresolved import
          bundle = pkgs.runCommand "${name}.js" { } /* bash */ ''
            ${lib.optionalString (npmRoot != null) "export NODE_PATH=${nodeModules}/node_modules"}
            ${lib.getExe pkgs.bun} build --target bun --outfile $out ${pkgs.writeText "${name}.ts" script}
          '';
        in
        # Read from stdin: Bun lists all of /nix/store when a script's path is in it, oven-sh/bun#32389
        pkgs.writeShellScriptBin name /* bash */ ''
          exec ${lib.getExe pkgs.bun} run - "$@" < ${bundle}
        '';
    };
}
