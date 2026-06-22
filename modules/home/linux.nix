{ self, ... }:
{
  flake.homeModules.linux =
    { config, ... }:
    let
      inherit (config.home) homeDirectory;
    in
    {
      imports = [ self.homeModules.common ];

      home = {
        homeDirectory = "/home/${config.home.username}";
      };

      services = {
        mpd = {
          enable = true;
          musicDirectory = "${homeDirectory}/sync/music";
          playlistDirectory = "${homeDirectory}/sync/playlists";
          extraConfig = ''
            restore_paused "yes"
            auto_update "yes"

            audio_output {
              type "pipewire"
              name "PipeWire"
            }
          '';
        };

        mpdris2 = {
          enable = true;
          notifications = true;
        };

      };
    };
}
