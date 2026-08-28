{ self, ... }:
{
  perSystem =
    {
      pkgs,
      self',
      ...
    }:
    {
      packages = self.lib.onlySupported {
        audio-output-switcher = pkgs.writeShellApplication {
          name = "audio-output-switcher";
          meta.platforms = pkgs.lib.platforms.linux;
          runtimeInputs = with pkgs; [
            coreutils # cut
            self'.packages.fzf-wrapped
            jq
            libnotify
            pipewire # provides pw-dump
            wireplumber # provides wpctl
          ];
          inheritPath = false;
          text = builtins.readFile ./audio-output-switcher;
        };
      };
    };
}
