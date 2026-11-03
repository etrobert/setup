_: {
  flake.nixosModules.imgproxy =
    { pkgs, ... }:
    let
      port = 8889;
    in
    {
      services.caddy.virtualHosts."images.etiennerobert.com".extraConfig = /* caddy */ ''
        reverse_proxy localhost:${toString port}
      '';

      systemd.services.imgproxy = {
        description = "imgproxy";
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ];
        serviceConfig = {
          ExecStart = "${pkgs.imgproxy}/bin/imgproxy";
          Restart = "on-failure";
          DynamicUser = true;
          Environment = [
            "IMGPROXY_JPEG_PROGRESSIVE=true"
            "IMGPROXY_BIND=localhost:${toString port}"
            "IMGPROXY_LOCAL_FILESYSTEM_ROOT=/tank/public"
            "IMGPROXY_USE_ETAG=true"
            "IMGPROXY_ALLOWED_SOURCES=local://"
          ];
        };
      };
    };
}
