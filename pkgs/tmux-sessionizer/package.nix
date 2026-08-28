{
  self',
  inputs',
  writeShellApplication,
  symlinkJoin,
  coreutils,
  gnused,
  eza,
  curl,
  findutils,
  gh,
}:
let
  script = writeShellApplication {
    name = "tmux-sessionizer";
    runtimeInputs = [
      coreutils
      curl
      # pronto spawns gh itself; pinning it here keeps the picker's fan-out off
      # whatever PATH happens to hold.
      gh
      gnused
      inputs'.pronto.packages.default
      self'.packages.tmux-wrapped
      self'.packages.git-wrapped
      self'.packages.fzf-wrapped
      eza
      findutils
    ];
    inheritPath = true;
    text = builtins.readFile ./tmux-sessionizer.sh;
  };
in
symlinkJoin {
  name = "tmux-sessionizer";
  paths = [ script ];
  postBuild = ''
    ln -s tmux-sessionizer $out/bin/ts
    mkdir -p $out/share/zsh/site-functions
    cp ${./_tmux-sessionizer} $out/share/zsh/site-functions/_tmux-sessionizer
  '';
}
