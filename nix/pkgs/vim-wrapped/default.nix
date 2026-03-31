{
  symlinkJoin,
  makeWrapper,
  vim,
}:
# TODO: --set PATH
symlinkJoin {
  name = "vim-wrapped";
  nativeBuildInputs = [ makeWrapper ];
  paths = [ vim ];
  meta.mainProgram = "vim";
  postBuild = ''
    wrapProgram $out/bin/vim \
      --add-flags "--cmd 'set rtp^=${./rtp}'" \
      --add-flags "-u ${./vimrc}"
  '';
}
