_: {
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
