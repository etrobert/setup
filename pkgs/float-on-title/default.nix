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
        float-on-title = pkgs.writeShellApplication {
          name = "float-on-title";
          meta.platforms = lib.platforms.linux;
          runtimeInputs = with pkgs; [
            jq
            niri
          ];
          inheritPath = false;
          text = builtins.readFile ./float-on-title.sh;
        };
      };
    };
}
