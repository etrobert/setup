{ self, inputs, ... }:
{
  flake.nixosModules.dispatch =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      inherit (pkgs.stdenv.hostPlatform) system;
    in
    {
      imports = [ inputs.dispatch.nixosModules.default ];

      services.dispatch = {
        enable = true;
        claudeBin = lib.getExe self.packages.${system}.claude-code-wrapped;
        gitPackage = self.packages.${system}.git-wrapped;
        tokenFile = config.sops.templates.dispatch-claude-token.path;
        githubTokenFile = config.sops.templates.dispatch-github-token.path;
      };

      # From `claude setup-token`; expires yearly.
      sops.secrets.dispatch-claude-token.sopsFile = ../../secrets/tower.yaml;
      sops.templates.dispatch-claude-token.content = "CLAUDE_CODE_OAUTH_TOKEN=${config.sops.placeholder.dispatch-claude-token}\n";

      # A fine-grained token over all repositories. Agents push branches and
      # open pull requests with it.
      sops.secrets.dispatch-github-token.sopsFile = ../../secrets/tower.yaml;
      sops.templates.dispatch-github-token.content = "GH_TOKEN=${config.sops.placeholder.dispatch-github-token}\n";
    };
}
