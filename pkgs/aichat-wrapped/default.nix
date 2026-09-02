_: {
  perSystem =
    {
      config,
      pkgs,
      lib,
      inputs',
      self',
      ...
    }:
    {
      packages.aichat-wrapped =
        let
          # Our fork (see flake.nix); newer than nixpkgs, which needs Enter for -e.
          aichat = inputs'.aichat.packages.default;

          # Declares its own wiring, so it is not in the package scope.
          inherit (self'.packages) claude-code-wrapped;

          # Both backends in one config: `??` takes the default, `???` asks for claude
          # with -m.
          configFile = pkgs.writeText "aichat.yaml" (
            builtins.replaceStrings [ "@claude@" ] [ (lib.getExe claude-code-wrapped) ] (
              builtins.readFile ./config.yaml
            )
          );
        in
        config.lib.wrapPackage {
          package = aichat;
          # aichat runs the accepted command by spawning `$SHELL -c`, which needs PATH.
          inheritPath = true;
          setDefaults.AICHAT_CONFIG_FILE = "${configFile}";
          # --dry-run fails the build on wrong config
          checks = [
            "AICHAT_CONFIG_FILE=${configFile} HOME=$(mktemp -d) ${aichat}/bin/aichat --dry-run -e 'list files' >/dev/null"
          ];
        };
    };
}
