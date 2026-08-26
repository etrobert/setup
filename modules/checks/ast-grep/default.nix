{ self, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      # sgconfig.yml stays at the repo root so the ast-grep LSP finds the project.
      checks.ast-grep = pkgs.runCommand "ast-grep-check" { nativeBuildInputs = [ pkgs.ast-grep ]; } ''
        ast-grep --config ${self}/sgconfig.yml scan ${self} && touch $out
      '';
    };
}
