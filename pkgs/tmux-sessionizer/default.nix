{
  self',
  writeShellApplication,
  symlinkJoin,
  coreutils,
  gnused,
  eza,
  fzf,
  findutils,
}:
let
  script = writeShellApplication {
    name = "tmux-sessionizer";
    runtimeInputs = [
      coreutils
      gnused
      self'.packages.tmux-wrapped
      eza
      fzf
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
