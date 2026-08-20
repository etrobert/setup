# Sync server for the atuin shell history client (pkgs/atuin-wrapped).
#
# Records are encrypted client-side, so tower stores blobs it cannot read; the
# tailnet-only exposure is what keeps the endpoint itself private. Clients
# address it as http://tower:8888 — plaintext inside WireGuard, and no tsnsrv
# name because only config files ever name it.
_: {
  flake.nixosModules.atuinServer =
    { config, ... }:
    {
      # Not services.atuin.openFirewall: that opens the port on every
      # interface, LAN included. Scoped to the tailnet, as immich does.
      networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ config.services.atuin.port ];

      services.atuin = {
        enable = true;

        # Bind everywhere and let the firewall above do the scoping, so the
        # address survives the Tailscale IP changing.
        host = "0.0.0.0";

        # The server offers no other way to create an account, so registering
        # the one account means flipping this true in the working tree, running
        # `atuin register`, and switching back to a clean tree. Keeping it false
        # here means the temporary state cannot outlive the checkout it lives in.
        openRegistration = false;
      };
    };
}
