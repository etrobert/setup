_: {
  perSystem =
    { pkgs, lib, ... }:
    {
      # Plugin support (needed by Tubifarry) is only on Lidarr's develop branch.
      # Once nixpkgs ships a version at least this new, check whether it loads
      # plugins: if so drop this package, otherwise raise the bound.
      packages.lidarr-develop =
        assert lib.assertMsg (lib.versionOlder pkgs.lidarr.version "3.1.6.5078")
          "nixpkgs lidarr ${pkgs.lidarr.version} caught up with lidarr-develop — see modules/pkgs/lidarr-develop/default.nix";
        pkgs.stdenv.mkDerivation (finalAttrs: {
          pname = "lidarr-develop";
          version = "3.1.6.5078";

          src = pkgs.fetchurl {
            url = "https://github.com/Lidarr/Lidarr/releases/download/v${finalAttrs.version}/Lidarr.develop.${finalAttrs.version}.linux-core-x64.tar.gz";
            hash = "sha256-HYFPI3bKbFxP6R/M2uOksR+xA06zRyC+Sd9wi8+MK4E=";
          };

          nativeBuildInputs = [ pkgs.makeWrapper ];

          installPhase = ''
            runHook preInstall

            mkdir --parents $out/bin $out/share/lidarr
            cp --recursive . $out/share/lidarr

            makeWrapper ${pkgs.dotnetCorePackages.aspnetcore_8_0}/bin/dotnet $out/bin/Lidarr \
              --add-flags $out/share/lidarr/Lidarr.dll \
              --prefix LD_LIBRARY_PATH : ${
                lib.makeLibraryPath (
                  with pkgs;
                  [
                    curl
                    icu
                    openssl
                    sqlite
                    zlib
                  ]
                )
              }

            runHook postInstall
          '';

          meta.mainProgram = "Lidarr";
        });
    };
}
