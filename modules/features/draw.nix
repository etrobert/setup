# draw.etiennerobert.com: the Excalidraw app, static files only.
{ self, ... }:
{
  flake.nixosModules.draw =
    { pkgs, ... }:
    let
      inherit (pkgs.stdenv.hostPlatform) system;
    in
    {
      networking.firewall.allowedTCPPorts = [
        80
        443
      ];

      services.caddy = {
        enable = true;
        virtualHosts."draw.etiennerobert.com".extraConfig = /* caddy */ ''
          root * ${self.packages.${system}.excalidraw}
          encode zstd gzip
          try_files {path} /index.html
          file_server
        '';
      };
    };
}
