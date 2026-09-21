{
  bun,
  git,
  lib,
  makeWrapper,
  stdenvNoCC,
}:
stdenvNoCC.mkDerivation {
  name = "claude-plan-usage";
  src = ./claude-plan-usage.ts;
  dontUnpack = true;
  nativeBuildInputs = [
    bun
    makeWrapper
  ];

  # --compile: run from a store path, bun would otherwise walk up looking for
  # a package.json and list all of /nix/store on every start (~150 ms)
  buildPhase = ''
    bun build --compile $src --outfile claude-plan-usage
  '';

  # strip would remove the ELF sections the script is embedded in
  dontStrip = true;

  installPhase = ''
    install -D claude-plan-usage $out/bin/claude-plan-usage
    wrapProgram $out/bin/claude-plan-usage --set PATH ${lib.makeBinPath [ git ]}
  '';
}
