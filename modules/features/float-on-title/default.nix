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

  flake.nixosModules.float-on-title =
    { lib, pkgs, ... }:
    let
      inherit (pkgs.stdenv.hostPlatform) system;
      inherit (self.packages.${system}) float-on-title;
    in
    {
      systemd.user.services.float-on-title = {
        description = "Float niri windows that set their title after opening";
        after = [ "graphical-session.target" ];
        partOf = [ "graphical-session.target" ];
        wantedBy = [ "graphical-session.target" ];

        serviceConfig = {
          # systemd resolves a slash-less ExecStart against /usr/bin, not PATH,
          # and eats single backslashes — hence the store path and the doubling.
          ExecStart = lib.concatStringsSep " " [
            (lib.getExe float-on-title)
            "'^(firefox|zen)$'"
            "'^Extension: \\\\(Bitwarden Password Manager\\\\)'"
          ];
          Restart = "on-failure";
        };
      };
    };
}
