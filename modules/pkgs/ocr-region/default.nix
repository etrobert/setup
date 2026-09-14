{ self, ... }:
{
  perSystem =
    { pkgs, lib, ... }:
    {
      packages = self.lib.onlySupported {
        ocr-region = pkgs.writeShellApplication {
          name = "ocr-region";
          meta.platforms = lib.platforms.linux;
          runtimeInputs = with pkgs; [
            grim
            libnotify
            slurp
            (tesseract.override {
              enableLanguages = [
                "eng"
                "deu"
              ];
            })
            wl-clipboard
          ];
          inheritPath = false;
          text = builtins.readFile ./ocr-region;
        };
      };
    };
}
