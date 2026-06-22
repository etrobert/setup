{ self, ... }:
{
  flake.homeModules.linux =
    { config, ... }:
    {
      imports = [ self.homeModules.common ];

      home = {
        homeDirectory = "/home/${config.home.username}";
      };
    };
}
