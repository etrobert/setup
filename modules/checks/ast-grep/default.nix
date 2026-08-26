{ self, ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      config = pkgs.writeText "sgconfig.yml" /* yaml */ ''
        ---
        ruleDirs:
          - ${./rules}
      '';
    in
    {
      checks.ast-grep = pkgs.runCommand "ast-grep-check" { nativeBuildInputs = [ pkgs.ast-grep ]; } ''
        ast-grep --config ${config} scan ${self} && touch $out
      '';
    };
}
