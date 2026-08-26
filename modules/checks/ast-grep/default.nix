{ self, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      checks.ast-grep = pkgs.runCommand "ast-grep-check" { nativeBuildInputs = [ pkgs.ast-grep ]; } ''
        # cd: ast-grep finds sgconfig.yml from the cwd, not from the scanned path.
        cd ${self} && ast-grep scan && touch $out
      '';
    };
}
