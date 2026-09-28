_: {
  perSystem =
    { pkgs, lib, ... }:
    {
      writers.writeNodeBin =
        name:
        {
          # A directory with the package.json and package-lock.json of the script's imports
          npmRoot,
        }:
        script:
        let
          nodeModules = pkgs.importNpmLock.buildNodeModules {
            inherit npmRoot;
            inherit (pkgs) nodejs;
          };
        in
        pkgs.runCommand name
          {
            nativeBuildInputs = [ pkgs.makeBinaryWrapper ];
            meta.mainProgram = name;
          }
          /* bash */ ''
            mkdir --parents $out/bin $out/lib
            cp ${pkgs.writeText "${name}.ts" script} $out/lib/${name}.ts
            # import ignores NODE_PATH, so node_modules sits next to the script
            ln --symbolic ${nodeModules}/node_modules $out/lib/node_modules
            ${lib.getExe pkgs.nodejs} --check $out/lib/${name}.ts
            makeWrapper ${lib.getExe pkgs.nodejs} $out/bin/${name} --add-flags $out/lib/${name}.ts
          '';
    };
}
