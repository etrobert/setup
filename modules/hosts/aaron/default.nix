{
  self,
  inputs,
  ...
}:
let
  inherit (inputs)
    nix-darwin
    home-manager
    agenix
    nix-homebrew
    ;
in
{
  flake.darwinConfigurations.aaron = nix-darwin.lib.darwinSystem {
    specialArgs = {
      inherit
        self
        agenix
        nix-darwin
        ;
    };
    modules = [
      self.darwinModules.aaron-configuration
      home-manager.darwinModules.home-manager
      agenix.darwinModules.default
      (
        { lib, ... }:
        # agenix reads users.users.<owner>.group, which nix-darwin users lack; "0" was its old fallback.
        assert lib.assertMsg (lib.hasInfix ''{ group = "0"; } (attrValues users)).group;'' (
          builtins.readFile "${agenix}/modules/age.nix"
        )) "agenix changed its secret group default — drop the override in modules/hosts/aaron/default.nix";
        {
          options.age.secrets = lib.mkOption {
            type = lib.types.attrsOf (lib.types.submodule { group = lib.mkDefault "0"; });
          };
        }
      )
      nix-homebrew.darwinModules.nix-homebrew
      {
        nix-homebrew = {
          enable = true;
          enableRosetta = true;
          user = "soft";
        };
      }
      self.darwinModules.workstation
      self.darwinModules.base
      self.darwinModules.git
      self.darwinModules.unfree
      self.darwinModules.nix-index
      self.darwinModules.ntfy-desktop
      self.darwinModules.github-runner
      self.darwinModules.atuin-login
    ];
  };
}
