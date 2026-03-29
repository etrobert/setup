{
  symlinkJoin,
  makeWrapper,
  tmux,
}:
# TODO: --set PATH
symlinkJoin {
  name = "tmux-wrapped";
  nativeBuildInputs = [ makeWrapper ];
  paths = [ tmux ];
  postBuild = ''
    wrapProgram $out/bin/tmux \
      --add-flags "-f ${./tmux.conf}"
  '';
}
