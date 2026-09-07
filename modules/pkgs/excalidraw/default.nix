_: {
  perSystem =
    { pkgs, lib, ... }:
    {
      packages.excalidraw =
        let
          # excalidraw-app's package.json pins engines.node to "18.0.0 - 22.x.x",
          # and yarn refuses to run a script under a node outside that range — so
          # yarn's own interpreter has to be pinned too. Called by absolute path
          # because yarnConfigHook propagates a default-node yarn ahead of ours.
          yarn = pkgs.yarn.override { nodejs = pkgs.nodejs_22; };
        in
        pkgs.stdenv.mkDerivation (finalAttrs: {
          pname = "excalidraw";
          version = "0.18.1";

          src = pkgs.fetchFromGitHub {
            owner = "excalidraw";
            repo = "excalidraw";
            tag = "v${finalAttrs.version}";
            hash = "sha256-XhxNXi6JwBq5vw+/6HQTp6NPX3etmCkdBdNboeBru/k=";
          };

          yarnOfflineCache = pkgs.fetchYarnDeps {
            yarnLock = "${finalAttrs.src}/yarn.lock";
            hash = "sha256-otUEr4bGhOGYQmfELShqc8lXbRs0gA0ycbGHzyCW8tc=";
          };

          nativeBuildInputs = [
            pkgs.yarnConfigHook
            pkgs.nodejs_22
          ];

          buildPhase = ''
            runHook preBuild
            ${lib.getExe yarn} --cwd excalidraw-app build:app:docker
            runHook postBuild
          '';

          installPhase = ''
            runHook preInstall
            cp -r excalidraw-app/build $out
            runHook postInstall
          '';
        });
    };
}
