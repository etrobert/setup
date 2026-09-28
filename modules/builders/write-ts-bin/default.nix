_: {
  perSystem =
    { pkgs, lib, ... }:
    {
      writers.writeTsBin =
        name: script:
        pkgs.buildNpmPackage {
          inherit name;
          # package.json lists the dependencies of every script
          src = ./.;
          npmDeps = pkgs.importNpmLock { npmRoot = ./.; };
          npmConfigHook = pkgs.importNpmLock.npmConfigHook;
          # From nixpkgs: npm's typescript and esbuild would fetch a binary for every platform
          nativeBuildInputs = with pkgs; [
            typescript
            esbuild
          ];
          buildPhase = /* bash */ ''
            cp ${script} ${name}.ts
            tsc
            # zx's ES module entry wraps its CommonJS build, which calls require
            esbuild ${name}.ts --bundle --platform=node --format=esm \
              --banner:js='import { createRequire as __createRequire } from "node:module"; const require = __createRequire(import.meta.url);' \
              --outfile=${name}.mjs
          '';
          installPhase = /* bash */ ''
            install -D ${name}.mjs $out/lib/${name}.mjs
            # zx runs commands through bash
            makeWrapper ${lib.getExe pkgs.nodejs} $out/bin/${name} \
              --add-flags $out/lib/${name}.mjs \
              --prefix PATH : ${lib.makeBinPath [ pkgs.bashNonInteractive ]}
          '';
          meta.mainProgram = name;
        };
    };
}
