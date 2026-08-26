_: {
  perSystem =
    { pkgs, ... }:
    {
      # Reverse-engineered proxy that exposes GitHub Copilot as an OpenAI/Anthropic
      # compatible server (https://github.com/ericc-ch/copilot-api). Fetched from npm
      # at runtime via npx; bump the pinned version below to upgrade.
      #
      # bash is required because npm/npx spawn `sh` at runtime; with inheritPath = false
      # it must be on PATH explicitly, otherwise the proxy dies with "spawn sh ENOENT"
      # under the minimal systemd environment.
      packages.copilot-api = pkgs.writeShellApplication {
        name = "copilot-api";
        runtimeInputs = [
          pkgs.nodejs_26
          pkgs.bash
        ];
        inheritPath = false;
        text = /* bash */ ''
          exec npx -y copilot-api@0.7.0 "$@"
        '';
      };
    };

  flake.nixosModules.copilot-api =
    {
      self,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (pkgs.stdenv.hostPlatform) system;
      inherit (self.packages.${system}) copilot-api claude-code-wrapped-copilot;
    in
    {
      environment.systemPackages = [ claude-code-wrapped-copilot ];

      # Local proxy exposing GitHub Copilot as an Anthropic-compatible API on
      # :4141, so claude-code-wrapped-copilot can route to Copilot's Claude
      # models using the GitHub Copilot subscription.
      #
      # Requires a one-time `copilot-api auth` per machine to populate the token
      # at ~/.local/share/copilot-api/github_token; until then the service fails
      # and retries harmlessly.
      systemd.user.services.copilot-api = {
        description = "GitHub Copilot -> Anthropic API proxy for Claude Code";
        wantedBy = [ "default.target" ];
        unitConfig.ConditionUser = "!@system";
        serviceConfig = {
          ExecStart = "${lib.getExe copilot-api} start --port 4141";
          Restart = "on-failure";
          RestartSec = "30s";
          # npx fetches the package from npm on first start; make TLS CAs resolve
          # in the minimal user-service environment.
          Environment = "SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt";
          Slice = "background.slice";
        };
      };
    };
}
