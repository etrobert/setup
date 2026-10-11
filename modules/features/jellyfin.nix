_: {
  flake.nixosModules.jellyfin =
    { config, lib, ... }:
    let
      libraries = {
        Movies = {
          type = "movies";
          path = "/tank/media/movies";
        };
        Shows = {
          type = "tvshows";
          path = "/tank/media/tv";
        };
      };

      # Unset options keep Jellyfin's defaults, which fetch metadata and posters from TMDb.
      options = builtins.toFile "options.xml" /* xml */ ''
        <?xml version="1.0" encoding="utf-8"?>
        <LibraryOptions>
          <EnableRealtimeMonitor>true</EnableRealtimeMonitor>
        </LibraryOptions>
      '';

      root = "${config.services.jellyfin.dataDir}/root/default";

      # libraries is the whole list: one added in the UI goes at the next restart.
      removeUndeclared = /* bash */ ''
        for dir in '${root}'/*/; do
          case "$(basename "$dir")" in
            ${lib.concatMapStringsSep "|" lib.escapeShellArg (lib.attrNames libraries)}) ;;
            *) rm --recursive -- "$dir" ;;
          esac
        done
      '';

      # Jellyfin registers a new library only at its next library scan.
      writeLibrary =
        name:
        { type, path }:
        let
          dir = "${root}/${name}";
        in
        /* bash */ ''
          mkdir --parents '${dir}'
          touch '${dir}/${type}.collection'
          printf '%s' '${path}' > '${dir}/${baseNameOf path}.mblink'
          cp --no-preserve=mode '${options}' '${dir}/options.xml'
        '';
    in
    {
      services = {
        jellyfin = {
          enable = true;

          hardwareAcceleration = {
            enable = true;
            type = "vaapi";
            # The RX 9070 XT by PCI path: renderD numbers can swap with the iGPU's.
            device = "/dev/dri/by-path/pci-0000:03:00.0-render";
          };

          transcoding = {
            enableHardwareEncoding = true;
            hardwareEncodingCodecs.hevc = true;
            # The card's VLD profiles in vainfo.
            hardwareDecodingCodecs = {
              h264 = true;
              hevc = true;
              hevc10bit = true;
              vp9 = true;
              av1 = true;
            };
          };

          forceEncodingConfig = true;
        };

        # Jellyfin's own login is the gate; 8096 itself is opened nowhere.
        caddy.virtualHosts."watch.etiennerobert.com".extraConfig = /* caddy */ ''
          reverse_proxy localhost:8096
        '';
      };

      # Jellyfin tone-maps HDR on AMD through OpenCL, which needs ROCm's runtime.
      hardware.amdgpu.opencl.enable = true;

      systemd.services.jellyfin = {
        # Libraries live under /tank/media; a scan before the mount marks them missing.
        unitConfig.RequiresMountsFor = [ "/tank/media" ];

        # ROCm's OpenCL opens /dev/kfd next to the render node the module allows.
        serviceConfig.DeviceAllow = [ "/dev/kfd rw" ];

        # preStart, not tmpfiles: Jellyfin caches options.xml, so a change must restart it.
        preStart = lib.concatLines ([ removeUndeclared ] ++ lib.mapAttrsToList writeLibrary libraries);
      };
    };
}
