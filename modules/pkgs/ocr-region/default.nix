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
            coreutils # wl-copy execs cat
            grim
            grim
            libnotify
            slurp
            slurp
            (tesseract.override {
              enableLanguages = [
                "eng"
                "deu"
                "fra"
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
