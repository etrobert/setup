{
  self,
  inputs,
  ...
}:
let
  inherit (inputs)
    nixpkgs
    agenix
    ;
in
{
  flake.nixosConfigurations.tower = nixpkgs.lib.nixosSystem {
    specialArgs = {
      inherit
        self
        agenix
        ;
    };
    modules = [
      self.nixosModules.tower-configuration
      self.nixosModules.nix-index
      agenix.nixosModules.default
      self.nixosModules.nixos-workstation
      self.nixosModules.workstation
      self.nixosModules.nixos-base
      self.nixosModules.base
      self.nixosModules.unfree
      self.nixosModules.server
      self.nixosModules.ntfy
      self.nixosModules.claude-warmup
      self.nixosModules.github-issue-watch
      self.nixosModules.kleinanzeigen-watch
      self.nixosModules.docker
      self.nixosModules.gaming
      self.nixosModules.fn-keys-on-focus
      self.nixosModules.screen-watch
      self.nixosModules.github-runner
      self.nixosModules.harmonia
      self.nixosModules.navidrome
      self.nixosModules.home-assistant
      self.nixosModules.tower-storage
      self.nixosModules.samba
      self.nixosModules.immich
      self.nixosModules.ollama
      # Off while python3Packages.posthog is broken by mcp 2 (NixOS/nixpkgs#578265)
      # self.nixosModules.open-webui
      (
        { pkgs, ... }:
        {
          assertions = [
            {
              assertion = pkgs.python3Packages.posthog.meta.broken;
              message = "python3Packages.posthog is no longer broken: re-enable open-webui in modules/hosts/tower/default.nix";
            }
          ];
        }
      )
      self.nixosModules.tailnet-services
      self.nixosModules.node-exporter
      self.nixosModules.smartctl-exporter
      self.nixosModules.dispatch
      self.nixosModules.taskgraph
      self.nixosModules.miniflux
      self.nixosModules.postgresql-read-access
      self.nixosModules.download-pull
      self.nixosModules.lidarr
      self.nixosModules.radarr
      self.nixosModules.jellyfin
      self.nixosModules.monitor-gpu-wake
      self.nixosModules.reboot-on-hang
    ];
  };
}
