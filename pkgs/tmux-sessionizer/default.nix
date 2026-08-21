{
  self',
  writeShellApplication,
  symlinkJoin,
  coreutils,
  gnused,
  eza,
  curl,
  findutils,
  gh,
  jq,
}:
let
  script = writeShellApplication {
    name = "tmux-sessionizer";
    runtimeInputs = [
      coreutils
      curl
      gh
      gnused
      jq
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
