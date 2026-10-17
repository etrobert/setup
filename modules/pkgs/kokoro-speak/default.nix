{ self, ... }:
{
  perSystem =
    {
      pkgs,
      lib,
      self',
      ...
    }:
    {
      packages = self.lib.onlySupported {
        kokoro-speak = self'.legacyPackages.wrapPackage {
          package = pkgs.writers.writePython3Bin "kokoro-speak" {
            libraries = with pkgs.python3Packages; [
              kokoro
              # Kokoro's English phonemizer loads it, and would otherwise pip install it.
              spacy-models.en_core_web_sm
            ];
          } (builtins.readFile ./kokoro-speak.py);
          runtimeInputs = [ pkgs.pipewire ];
          platforms = lib.platforms.linux;
        };
      };
    };
}
