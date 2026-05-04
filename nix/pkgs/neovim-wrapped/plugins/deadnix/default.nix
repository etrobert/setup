{ pkgs, ... }:
let
  deadnix-errfmt = pkgs.writeShellScriptBin "deadnix-errfmt" /* bash */ ''
    ${pkgs.deadnix}/bin/deadnix --output-format json "$@" | \
      ${pkgs.jq}/bin/jq -r '.file as $f | .results[] | $f + ">" + (.line|tostring) + ":" + (.column|tostring) + ":W:0:" + .message'
  '';

  deadnix-compiler = pkgs.vimUtils.buildVimPlugin {
    pname = "deadnix-compiler";
    version = "0";
    src = ./src;
  };
in
{
  plugins = [
    {
      plugin = deadnix-compiler;
      extraPackages = [ deadnix-errfmt ];
    }
  ];
}
