_: {
  flake.overlays.kanata-main = (
    final: prev: {
      kanata = prev.kanata.overrideAttrs (_: rec {
        doCheck = false;
        version = "main";
        src = final.fetchFromGitHub {
          owner = "jtroo";
          repo = "kanata";
          rev = "484368f406584255208dfd59359130f3769baf52";
          hash = "sha256-IXnYds2pHLS0dOh2vDSP/0bA/8YmCuprJXAOgI0TDn4=";
        };
        cargoDeps = prev.rustPlatform.importCargoLock {
          lockFile = "${src}/Cargo.lock";
        };
      });
    }
  );
}
