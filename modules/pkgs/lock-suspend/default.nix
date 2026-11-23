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
        lock-suspend = pkgs.writeShellApplication {
          name = "lock-suspend";
          meta.platforms = lib.platforms.linux;
          runtimeInputs = with pkgs; [
            coreutils # sleep
            systemd
          ];
          inheritPath = false;
          text = ''
            loginctl lock-session
            sleep 1
            systemctl suspend
          '';
        };
      };
    };
}
