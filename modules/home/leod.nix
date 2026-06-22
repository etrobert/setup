{ self, ... }:
{
  flake.homeModules.leod = {
    imports = [
      self.homeModules.linux
    ];
  };
}
