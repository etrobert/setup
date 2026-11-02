{ self, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      packages = self.lib.onlySupported {
        helium =
          let
            pname = "helium";
            version = "0.20.3.1";

            src = pkgs.fetchurl {
              url = "https://github.com/imputnet/helium-linux/releases/download/${version}/helium-${version}-x86_64.AppImage";
              hash = "sha256-H69Thkj+FKHqkuMlyxI4rojEeGZsteY9DSrxcP5MoDc=";
            };

            contents = pkgs.appimageTools.extract { inherit pname version src; };
          in
          pkgs.appimageTools.wrapType2 {
            inherit pname version src;

            # Share programs.chromium's policies, which the FHS sandbox otherwise hides
            extraBwrapArgs = [ "--ro-bind-try /etc/chromium /etc/chromium" ];

            extraInstallCommands = ''
              install -D --mode=444 ${contents}/helium.desktop --target-directory=$out/share/applications
              install -D --mode=444 ${contents}/helium.png --target-directory=$out/share/icons/hicolor/256x256/apps
            '';

            meta.platforms = [ "x86_64-linux" ];
          };
      };
    };
}
