{
  self',
  writeShellApplication,
  symlinkJoin,
  coreutils,
  gnused,
  difftastic,
  eza,
  findutils,
  git,
}:
let
  script = writeShellApplication {
    name = "tmux-sessionizer";
    runtimeInputs = [
      coreutils
      gnused
      self'.packages.tmux-wrapped
      self'.packages.fzf-wrapped
      difftastic
      eza
      findutils
      git
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
