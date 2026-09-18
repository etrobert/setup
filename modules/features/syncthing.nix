_: {
  flake.nixosModules.syncthing =
    { self, ... }:
    {
      services.syncthing = {
        enable = true;
        user = "soft";
        dataDir = "/home/soft";
        openDefaultPorts = true;
        guiAddress = "0.0.0.0:8384";
        settings = self.lib.syncthingSettings { dataDir = "/home/soft"; };
      };
    };
}
