{ self, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      packages.xwayland-client-list = pkgs.writers.writePython3Bin "xwayland-client-list" {
        libraries = [ pkgs.python3Packages.xlib ];
      } (builtins.readFile ./xwayland-client-list.py);
    };

  flake.nixosModules.xwaylandClientList =
    { pkgs, lib, ... }:
    let
      inherit (pkgs.stdenv.hostPlatform) system;
    in
    {
      systemd.user.services.xwayland-client-list = {
        description = "Publish _NET_CLIENT_LIST that xwayland-satellite omits";
        after = [ "graphical-session.target" ];
        partOf = [ "graphical-session.target" ];
        wantedBy = [ "graphical-session.target" ];

        serviceConfig = {
          ExecStart = lib.getExe self.packages.${system}.xwayland-client-list;
          Restart = "on-failure";
        };
      };
    };
}
