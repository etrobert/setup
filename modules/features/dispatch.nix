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
      };

      # `CLAUDE_CODE_OAUTH_TOKEN=...` from `claude setup-token`; expires yearly.
      age.secrets.dispatch-claude-token.file = ../../secrets/dispatch-claude-token.age;
    };
}
