_: {
  flake.nixosModules.peira-configuration = _: {
    boot.isNspawnContainer = true;

    networking.hostName = "peira";
    # The host configures the container's interface.
    networking.useDHCP = false;

    system.stateVersion = "26.11";
  };
}
