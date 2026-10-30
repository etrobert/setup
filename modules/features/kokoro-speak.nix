{ self, ... }:
{
  flake.nixosModules.kokoro-speak =
    { pkgs, lib, ... }:
    {
      systemd.user.services.kokoro-speak = {
        description = "Speak text posted to localhost:8880 with Kokoro";
        wantedBy = [ "graphical-session.target" ];
        serviceConfig = {
          ExecStart = lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.kokoro-speak;
          Restart = "on-failure";
        };
      };
    };
}
