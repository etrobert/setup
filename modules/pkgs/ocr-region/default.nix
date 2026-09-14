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
            coreutils # wl-copy execs cat
            grim
            libnotify
            slurp
            (tesseract.override {
              enableLanguages = [
                "eng"
                "fra"
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
