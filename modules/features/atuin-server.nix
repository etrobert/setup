_: {
  flake.nixosModules.atuinServer =
    { config, ... }:
    {
      networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ config.services.atuin.port ];

      services.atuin = {
        enable = true;

        host = "0.0.0.0";

        # Flip true in the working tree to register the one account; never commit it.
        openRegistration = false;
      };
    };
}
