{ self, ... }:
{
  flake.homeModules.leod = self.homeModules.linux // self.homeModules.hypridle;
}
