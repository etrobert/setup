_: {
  flake.nixosModules.peira-configuration = _: {
    boot.isNspawnContainer = true;

    networking.hostName = "peira";
    # The host configures the container's interface.
    networking.useDHCP = false;

    # The store is the host's, read-only here; nixpkgs sets NIX_REMOTE for shells only.
    nix.settings.store = "daemon";

    # The host's shared services.
    # Prefixed: tower already serves its own lidarr.
    services.tsnsrv.services = {
      daddy-lidarr.toURL = "http://10.233.1.1:8686";
      daddy-transmission.toURL = "http://10.233.1.1:9091";
      daddy-slskd.toURL = "http://10.233.1.1:5030";
    };

    system.stateVersion = "26.11";
  };
}
