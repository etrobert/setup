_: {
  flake.nixosModules.peira-configuration = _: {
    boot.isNspawnContainer = true;

    networking.hostName = "peira";
    # The host configures the container's interface.
    networking.useDHCP = false;

    # The store is the host's, read-only here; nixpkgs sets NIX_REMOTE for shells only.
    nix.settings.store = "daemon";

    system.stateVersion = "26.11";
  };
}
