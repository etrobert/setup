{ pkgs, self', ... }:
let
  nix-check-errfmt = pkgs.writeShellApplication {
    name = "nix-check-errfmt";
    runtimeInputs = [
      pkgs.statix
      self'.packages.deadnix-errfmt
    ];
    inheritPath = false;
    text = ''
      statix check -o errfmt "$@"
      deadnix-errfmt "$@"
    '';
  };

  nix-check-compiler = pkgs.vimUtils.buildVimPlugin {
    pname = "nix-check-compiler";
    version = "0";
    src = ./src;
  };
in
{
  plugins = [
    {
      plugin = nix-check-compiler;
      extraPackages = [ nix-check-errfmt ];
    }
  ];
}
