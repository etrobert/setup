_: {
  flake.nixosModules.iphoneWebcam =
    { config, pkgs, ... }:
    let
      # Port IP Camera Lite serves on, tunnelled to the same port locally.
      port = 8081;

      # High number so the loopback never lands on /dev/video0 and shadows a
      # real UVC camera in apps that pick the lowest node.
      videoNr = 10;

      # IP Camera Lite's built-in defaults; the stream is only reachable over
      # the USB tunnel, so these never leave the machine.
      streamUrl = "http://admin:admin@127.0.0.1:${toString port}/video";
    in
    {
      boot = {
        extraModulePackages = [ config.boot.kernelPackages.v4l2loopback ];

        # exclusive_caps=1 makes the device announce itself as capture-only once
        # ffmpeg attaches, which is what Chrome needs to list it at all.
        extraModprobeConfig = ''
          options v4l2loopback devices=1 video_nr=${toString videoNr} card_label="iPhone" exclusive_caps=1
        '';
      };

      # Speaks to the iPhone over USB; iproxy connects through its socket.
      services.usbmuxd.enable = true;

      systemd.services = {
        iphone-webcam-tunnel = {
          description = "USB tunnel to IP Camera Lite on the iPhone";

          requires = [ "usbmuxd.service" ];
          after = [ "usbmuxd.service" ];

          serviceConfig = {
            ExecStart = "${pkgs.libusbmuxd}/bin/iproxy ${toString port}:${toString port}";
            Restart = "on-failure";

            # Torn down automatically once iphone-webcam stops needing it.
            StopWhenUnneeded = true;
          };
        };

        iphone-webcam = {
          description = "Expose the iPhone camera as a V4L2 device";

          requires = [
            "iphone-webcam-tunnel.service"
            "modprobe@v4l2loopback.service"
          ];

          after = [
            "iphone-webcam-tunnel.service"
            "modprobe@v4l2loopback.service"
          ];

          serviceConfig = {
            # 720p because Meet caps sending there anyway, and the smaller frame
            # keeps latency down.
            ExecStart = ''
              ${pkgs.ffmpeg}/bin/ffmpeg -loglevel warning \
                -i ${streamUrl} -an \
                -vf scale=-2:720,format=yuyv422 -r 30 \
                -f v4l2 /dev/video${toString videoNr}
            '';

            Restart = "always";
            RestartSec = 2;
          };
        };
      };
    };
}
