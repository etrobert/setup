# Backs aichat's `??` with `claude -p` instead of a raw model, so generated
# commands follow the conventions in CLAUDE.md (ntfy publish, nix run
# nixpkgs#…, the machines over Tailscale) rather than generic Linux defaults.
#
# aichat only speaks HTTP, so pkgs/aichat-shim exposes an OpenAI-compatible
# endpoint on :4142 that shells out to claude. pkgs/aichat-wrapped points at it.
_: {
  flake = {
    nixosModules.aichat-shim =
      {
        self,
        lib,
        pkgs,
        ...
      }:
      let
        inherit (pkgs.stdenv.hostPlatform) system;
      in
      {
        systemd.user.services.aichat-shim = {
          description = "claude -p behind an OpenAI-compatible endpoint for aichat";
          wantedBy = [ "default.target" ];
          unitConfig.ConditionUser = "!@system";

          serviceConfig = {
            ExecStart = lib.getExe self.packages.${system}.aichat-shim;
            Restart = "on-failure";
            RestartSec = "30s";
            Slice = "background.slice";
          };
        };
      };

    darwinModules.aichat-shim =
      {
        self,
        lib,
        pkgs,
        ...
      }:
      let
        inherit (pkgs.stdenv.hostPlatform) system;
      in
      {
        launchd.user.agents.aichat-shim = {
          serviceConfig = {
            ProgramArguments = [ (lib.getExe self.packages.${system}.aichat-shim) ];
            KeepAlive = true;
            RunAtLoad = true;
          };
        };
      };
  };
}
