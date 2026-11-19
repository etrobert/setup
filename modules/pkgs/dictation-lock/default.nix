_: {
  perSystem =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    {
      packages.dictation-lock = pkgs.writers.writePython3Bin "dictation-lock" {
        # The formatter spaces slice colons.
        flakeIgnore = [ "E203" ];
      } (builtins.readFile ./dictation-lock.py);

      # passes.txt is what Whisper returned for each pass of a real recording.
      checks.dictation-lock = pkgs.runCommand "dictation-lock-check" { } ''
        ${lib.getExe config.packages.dictation-lock} < ${./passes.txt} | diff - ${./locked.txt} && touch $out
      '';
    };
}
