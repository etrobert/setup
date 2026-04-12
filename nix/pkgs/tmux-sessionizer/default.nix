{
  self',
  writeShellApplication,
  symlinkJoin,
  coreutils,
  gnused,
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
    mkdir -p $out/share/zsh/site-functions
    cp ${./_tmux-sessionizer} $out/share/zsh/site-functions/_tmux-sessionizer
  '';
}
