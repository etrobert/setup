{ self, ... }:
{
  perSystem =
    {
      pkgs,
      lib,
      ...
    }:
    {
      packages = self.lib.onlySupported {
        scale-floating-window = pkgs.writeShellApplication {
          name = "scale-floating-window";
          meta.platforms = lib.platforms.linux;
          runtimeInputs = with pkgs; [
            jq
            niri
            gawk
          ];
          inheritPath = false;
          text = builtins.readFile ./scale-floating-window;
        };
      };
    };
}
