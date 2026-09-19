_: {
  flake.nixosModules.syncthing =
    { self, ... }:
    {
      services.syncthing = {
        enable = true;
        user = "soft";
        dataDir = "/home/soft";
        openDefaultPorts = true;
        settings = self.lib.syncthingSettings { dataDir = "/home/soft"; };
      };
    };
}
