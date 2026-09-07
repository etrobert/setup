_: {
  flake.nixosModules.jitsiMeet = _: {
    services.jitsi-meet = {
      enable = true;
      hostName = "meet.etiennerobert.com";
      caddy.enable = true;
      nginx.enable = false;
    };

    # Media port (UDP 10000) and its TCP 4443 fallback. Both still need
    # forwarding on the Vodafone Station; only 80/443 are forwarded today.
    services.jitsi-videobridge.openFirewall = true;

    # jitsi-meet inherits this marking from olm, which it uses only for the
    # opt-in E2EE feature. Pinned to the version so a bump fails the build and
    # forces a re-check of whether the marking is still there.
    nixpkgs.config.permittedInsecurePackages = [ "jitsi-meet-1.0.9365" ];
  };
}
