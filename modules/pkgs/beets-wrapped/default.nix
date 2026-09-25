_: {
  perSystem =
    { pkgs, self', ... }:
    {
      packages.beets-wrapped =
        let
          music = "/tank/media/music";
          yaml = pkgs.formats.yaml { };

          configFile = yaml.generate "beets-config.yaml" {
            directory = music;
            # The catalogue lives with the music: snapshotted, hidden from Navidrome.
            library = "${music}/.beets/library.db";
            statefile = "${music}/.beets/state.pickle";

            # $source is set per import: `beet import --set source=torrents …`
            paths = {
              default = "$source/$albumartist/$album%aunique{}/$track $title";
              singleton = "$source/Non-Album/$artist/$title";
              comp = "$source/Compilations/$album%aunique{}/$track $title";
            };

            # musicbrainz is the default; listing plugins replaces it.
            # copy leaves cover.jpg behind; fetchart carries it over (local first).
            plugins = [
              "musicbrainz"
              "fetchart"
            ];
          };

          configDir = pkgs.linkFarm "beets-config" [
            {
              name = "config.yaml";
              path = configFile;
            }
          ];
        in
        self'.legacyPackages.wrapPackage {
          package = pkgs.beets;
          setDefaults.BEETSDIR = configDir;
        };
    };
}
