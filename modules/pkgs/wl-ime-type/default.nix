{ self, ... }:
{
  perSystem =
    { pkgs, lib, ... }:
    {
      packages = self.lib.onlySupported {
        wl-ime-type = pkgs.stdenv.mkDerivation {
          pname = "wl-ime-type";
          version = "0-unstable-2025-08-17";
          src = pkgs.fetchFromGitLab {
            domain = "gitlab.freedesktop.org";
            owner = "emersion";
            repo = "wl-ime-type";
            rev = "bff37755ca66b958a6d6d7cf3126dc7da7518ee2";
            hash = "sha256-b8aeHeofLoIXXXzt6Z0PJAbvxQw4rzrDde6SyQxqi00=";
          };
          nativeBuildInputs = with pkgs; [
            pkg-config
            scdoc
            wayland-scanner
          ];
          buildInputs = [ pkgs.wayland ];
          makeFlags = [ "PREFIX=$(out)" ];
          meta = {
            mainProgram = "wl-ime-type";
            platforms = lib.platforms.linux;
          };
        };
      };
    };
}
