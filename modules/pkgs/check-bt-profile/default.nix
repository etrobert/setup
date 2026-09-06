_: {
  perSystem =
    { pkgs, ... }:
    {
      packages.check-bt-profile = pkgs.writeShellApplication {
        name = "check-bt-profile";
        runtimeInputs = with pkgs; [
          pulseaudio
          gnugrep
          gawk
        ];
        inheritPath = false;
        text = builtins.readFile ./check-bt-profile;
      };
    };
}
