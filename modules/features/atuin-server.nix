_: {
  flake.nixosModules.atuinServer =
    { config, ... }:
    {
      networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ config.services.atuin.port ];

      services.atuin = {
        enable = true;

        host = "0.0.0.0";

        # The server offers no other way to create an account, so registering
        # the one account means flipping this true in the working tree, running
        # `atuin register`, and switching back to a clean tree. Keeping it false
        # here means the temporary state cannot outlive the checkout it lives in.
        openRegistration = false;
      };
    };
}
