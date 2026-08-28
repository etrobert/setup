_: {
  perSystem =
    {
      pkgs,
      inputs',
      self',
      ...
    }:
    {
      packages.tmux-sessionizer =
        let
          script = pkgs.writeShellApplication {
            name = "tmux-sessionizer";
            runtimeInputs = [
              pkgs.coreutils
              pkgs.curl
              # pronto spawns gh itself; pinning it here keeps the picker's fan-out off
              # whatever PATH happens to hold.
              pkgs.gh
              pkgs.gnused
              inputs'.pronto.packages.default
              self'.packages.tmux-wrapped
              self'.packages.git-wrapped
              self'.packages.fzf-wrapped
              pkgs.eza
              pkgs.findutils
            ];
            inheritPath = true;
            text = builtins.readFile ./tmux-sessionizer.sh;
          };
        in
        pkgs.symlinkJoin {
          name = "tmux-sessionizer";
          paths = [ script ];
          postBuild = ''
            ln -s tmux-sessionizer $out/bin/ts
            mkdir -p $out/share/zsh/site-functions
            cp ${./_tmux-sessionizer} $out/share/zsh/site-functions/_tmux-sessionizer
          '';
        };
    };
}
