{ pkgs }:
pkgs.buildNpmPackage {
  pname = "strip-json-comments-cli";
  version = "3.0.0";
  src = pkgs.fetchFromGitHub {
    owner = "sindresorhus";
    repo = "strip-json-comments-cli";
    rev = "v3.0.0";
    hash = "sha256-aMp/1/TpEed6eHU7FCXMjAkX/2EcOyhR1cPDHek4Noc=";
  };
  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';
  npmDepsHash = "sha256-S6f7sw4GRdbSEuh1HfzC7dhbO5YVUJV9k4v+yUsWMYw=";
  dontNpmBuild = true;
  dontNpmPrune = true;
}
