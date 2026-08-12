# Backs aichat's `??` with `claude -p` instead of a raw model, so generated
# commands follow the conventions in CLAUDE.md (ntfy publish, nix run
# nixpkgs#…, the machines over Tailscale) rather than generic Linux defaults.
#
# aichat only speaks HTTP, so pkgs/aichat-shim exposes an OpenAI-compatible
# endpoint on :4142 that shells out to claude. pkgs/aichat-wrapped points at it.
#
# Two modules rather than one platform-branching module: deciding a module's
# attributes from `pkgs` is an infinite recursion, since `pkgs` itself comes
# from `config`. The workstation profile picks the right one per platform.
_:
let
  description = "claude -p behind an OpenAI-compatible endpoint for aichat";
in
{
  flake = {
    nixosModules.aichat-shim =
      {
        self,
        lib,
        pkgs,
        ...
      }:
      {
        systemd.user.services.aichat-shim = {
          inherit description;
          wantedBy = [ "default.target" ];
          unitConfig.ConditionUser = "!@system";

          serviceConfig = {
            ExecStart = lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.aichat-shim;
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
      {
        launchd.user.agents.aichat-shim.serviceConfig = {
          ProgramArguments = [
            (lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.aichat-shim)
          ];
          KeepAlive = true;
          RunAtLoad = true;
        };
      };
  };
}
