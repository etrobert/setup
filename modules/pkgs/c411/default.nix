_: {
  perSystem =
    { pkgs, lib, ... }:
    {
      packages.c411 = pkgs.buildGoModule {
        pname = "c411";
        version = "0.1.0";

        src = ./.;
        # Standard library only.
        vendorHash = null;

        nativeBuildInputs = [ pkgs.makeWrapper ];

        postInstall = ''
          wrapProgram $out/bin/c411 --prefix PATH : ${
            lib.makeBinPath [
              pkgs.fzf
              pkgs.transmission_4
            ]
          }
        '';

        meta.mainProgram = "c411";
      };
    };
}
