_: {
  flake =
    let
      tmuxModule =
        { pkgs, ... }:
        {
          # Plain tmux reads /etc/tmux.conf, so prefix r can reload a deployed config.
          # Loading it into a throwaway server fails the build on an invalid line.
          environment.etc."tmux.conf".source =
            pkgs.runCommand "tmux.conf" { nativeBuildInputs = [ pkgs.tmux ]; }
              /* bash */ ''
                TMUX_TMPDIR=$TMPDIR tmux -f /dev/null start-server \; source-file ${./tmux.conf}
                cp ${./tmux.conf} $out
              '';
          environment.systemPackages = [ pkgs.tmux ];
        };
    in
    {
      nixosModules.tmux = tmuxModule;
      darwinModules.tmux = tmuxModule;
    };
}
