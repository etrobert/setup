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
        tokenFile = config.age.secrets.dispatch-claude-token.path;
        githubTokenFile = config.age.secrets.dispatch-github-token.path;
      };

      # `CLAUDE_CODE_OAUTH_TOKEN=...` from `claude setup-token`; expires yearly.
      age.secrets.dispatch-claude-token.file = ../../secrets/dispatch-claude-token.age;

      # `GH_TOKEN=...`, a fine-grained token over all repositories. Agents push
      # branches and open pull requests with it.
      age.secrets.dispatch-github-token.file = ../../secrets/dispatch-github-token.age;
    };
}
