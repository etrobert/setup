{
  bun2nix,
  git,
  lib,
  makeWrapper,
}:
bun2nix.mkDerivation {
  packageJson = ./package.json;
  src = ./.;
  bunDeps = bun2nix.fetchBunDeps { bunNix = ./bun.nix; };
  # bytecode cannot carry a top-level await
  bunCompileToBytecode = false;

  nativeBuildInputs = [ makeWrapper ];
  postInstall = ''
    wrapProgram $out/bin/claude-plan-usage --set PATH ${lib.makeBinPath [ git ]}
  '';
}
