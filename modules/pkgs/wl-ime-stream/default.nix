{ self, ... }:
{
  perSystem =
    { pkgs, lib, ... }:
    {
      packages = self.lib.onlySupported {
        wl-ime-stream = pkgs.stdenv.mkDerivation {
          pname = "wl-ime-stream";
          version = "0-unstable-2025-08-17";
          # Upstream's Makefile and protocol file, built around our main.c.
          src = pkgs.fetchFromGitLab {
            domain = "gitlab.freedesktop.org";
            owner = "emersion";
            repo = "wl-ime-type";
            rev = "bff37755ca66b958a6d6d7cf3126dc7da7518ee2";
            hash = "sha256-b8aeHeofLoIXXXzt6Z0PJAbvxQw4rzrDde6SyQxqi00=";
          };
          postPatch = "cp ${./main.c} main.c";
          nativeBuildInputs = with pkgs; [
            pkg-config
            wayland-scanner
          ];
          buildInputs = [ pkgs.wayland ];
          buildFlags = [ "wl-ime-type" ];
          installPhase = "install -D wl-ime-type $out/bin/wl-ime-stream";
          meta = {
            mainProgram = "wl-ime-stream";
            platforms = lib.platforms.linux;
          };
        };
      };
    };
}
