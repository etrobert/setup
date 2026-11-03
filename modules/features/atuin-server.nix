_: {
  flake.nixosModules.atuin-server =
    { config, ... }:
    {
      networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ config.services.atuin.port ];

      ports.atuin = "auto";

      services.atuin = {
        enable = true;

        port = config.ports.atuin;

        host = "0.0.0.0";

        # Flip true in the working tree to register the one account; never commit it.
        openRegistration = false;
      };
    };
}
