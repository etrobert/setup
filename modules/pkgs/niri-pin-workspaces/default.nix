{ self, ... }:
{
  perSystem =
    { pkgs, lib, ... }:
    {
      packages = self.lib.onlySupported {
        niri-pin-workspaces = pkgs.writeShellApplication {
          name = "niri-pin-workspaces";
          meta.platforms = lib.platforms.linux;
          runtimeInputs = with pkgs; [
            gnugrep
            jq
            niri
            socat
          ];
          inheritPath = false;
          text = builtins.readFile ./niri-pin-workspaces;
        };
      };
    };
}
