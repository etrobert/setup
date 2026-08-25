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
      # 1 is findings (parse errors included, as errfmt records); 2+ is statix itself failing
      statix check -o errfmt "$@" || [ $? -eq 1 ]
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
