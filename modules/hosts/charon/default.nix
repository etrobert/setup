{
  self,
  inputs,
  ...
}:
{
  flake.nixosConfigurations.charon = inputs.nixpkgs.lib.nixosSystem {
    specialArgs = { inherit self; };
    system = "x86_64-linux";
    modules = [
      self.nixosModules.charon-configuration
      self.nixosModules.nixos-base
      self.nixosModules.base
      self.nixosModules.auto-upgrade
      self.nixosModules.tailnet-services
      self.nixosModules.transmission
      self.nixosModules.slskd
      self.nixosModules.node-exporter
      self.nixosModules.disk-space-alert
      self.nixosModules.metrics
      self.nixosModules.caddy
      self.nixosModules.draw
      self.nixosModules.countdown
      self.nixosModules.nutricalc
      self.nixosModules.creatures
      self.nixosModules.rift-radar
      self.nixosModules.umami
      self.nixosModules.atuin-server
      self.nixosModules.atuin-login
      self.nixosModules.ddclient
      inputs.agenix.nixosModules.default
    ];
  };
}
