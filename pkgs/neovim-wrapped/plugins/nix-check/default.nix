{ pkgs, self', ... }:
let
  nix-check-errfmt = pkgs.writeShellApplication {
    name = "nix-check-errfmt";
    runtimeInputs = [
      pkgs.statix
      self'.packages.deadnix-errfmt
    ];
    inheritPath = false;
    text = /* bash */ ''
      # statix exits 1 on findings, which errexit would turn into a skipped deadnix
      statix check -o errfmt "$@" || true
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
