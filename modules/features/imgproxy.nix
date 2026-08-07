_: {
  flake.nixosModules.imgproxy =
    { pkgs, ... }:
    {
      services.caddy.virtualHosts."images.etiennerobert.com".extraConfig = /* caddy */ ''
        reverse_proxy localhost:8889
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
            "IMGPROXY_BIND=localhost:8889"
            "IMGPROXY_LOCAL_FILESYSTEM_ROOT=/srv/files"
            "IMGPROXY_USE_ETAG=true"
            "IMGPROXY_ALLOWED_SOURCES=local://"
          ];
        };
      };
    };
}
