{ self, ... }:
{
  flake.homeModules.darwin =
    { config, ... }:
    {
      imports = [ self.homeModules.common ];

      home = {
        homeDirectory = "/Users/${config.home.username}";
      };
    };
}
