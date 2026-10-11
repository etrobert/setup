_: {
  flake.nixosModules.jellyfin =
    {
      config,
      lib,
      pkgs,
      ...
    }:
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

      # Only these keys: Jellyfin writes the rest of encoding.xml itself.
      encoding = {
        HardwareAccelerationType = "vaapi";
        # The RX 9070 XT by PCI path: renderD numbers can swap with the iGPU's.
        VaapiDevice = "/dev/dri/by-path/pci-0000:03:00.0-render";
        EnableDecodingColorDepth10Hevc = "true";
        EnableDecodingColorDepth10Vp9 = "true";
        EnableHardwareEncoding = "true";
        AllowHevcEncoding = "true";
        # On AMD it runs libplacebo through Vulkan; the OpenCL path would need ROCm.
        EnableTonemapping = "true";
      };

      # The card's VLD profiles in vainfo; it has no VC-1 or MPEG-2 decoder.
      decodingCodecs = [
        "h264"
        "hevc"
        "vp9"
        "av1"
      ];

      setEncoding =
        let
          setKey =
            name: value: "-d '/EncodingOptions/${name}' -s /EncodingOptions -t elem -n ${name} -v '${value}'";
          addCodec = codec: "-s /EncodingOptions/HardwareDecodingCodecs -t elem -n string -v ${codec}";
        in
        /* bash */ ''
          file='${config.services.jellyfin.configDir}/encoding.xml'
          [ -e "$file" ] || printf '%s\n' '<?xml version="1.0" encoding="utf-8"?>' '<EncodingOptions />' > "$file"
          ${lib.getExe pkgs.xmlstarlet} ed --inplace \
            ${lib.concatStringsSep " " (lib.mapAttrsToList setKey encoding)} \
            -d /EncodingOptions/HardwareDecodingCodecs -s /EncodingOptions -t elem -n HardwareDecodingCodecs \
            ${lib.concatMapStringsSep " " addCodec decodingCodecs} \
            "$file"
        '';
    in
    {
      services = {
        jellyfin.enable = true;

        # Jellyfin's own login is the gate; 8096 itself is opened nowhere.
        caddy.virtualHosts."watch.etiennerobert.com".extraConfig = /* caddy */ ''
          reverse_proxy localhost:8096
        '';
      };

      systemd.services.jellyfin = {
        # Libraries live under /tank/media; a scan before the mount marks them missing.
        unitConfig.RequiresMountsFor = [ "/tank/media" ];

        # preStart, not tmpfiles: Jellyfin caches options.xml, so a change must restart it.
        preStart = lib.concatLines (
          [
            removeUndeclared
            setEncoding
          ]
          ++ lib.mapAttrsToList writeLibrary libraries
        );
      };
    };
}
