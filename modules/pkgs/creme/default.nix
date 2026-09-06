_: {
  perSystem =
    { pkgs, ... }:
    {
      packages.creme = pkgs.writeShellApplication {
        name = "creme";
        runtimeInputs = [ pkgs.mpc ];
        inheritPath = false;
        text = ''
          song=$(mpc current --format "%file%")
          if [[ -z "$song" ]]; then
            echo "Nothing is currently playing"
            exit 1
          fi
          echo "$song" >>~/sync/music/playlists/creme.m3u
          echo "Added: $song"
        '';
      };
    };
}
