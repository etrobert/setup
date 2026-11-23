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
        lock=${lib.getExe config.packages.dictation-lock}
        $lock < ${./passes.txt} | diff - ${./locked.txt}
        printf 'Ask not.\n%.0s' {1..6} | $lock | tail --lines=1 | diff - <(printf 'Ask not.\t\n')
        touch $out
      '';
    };
}
