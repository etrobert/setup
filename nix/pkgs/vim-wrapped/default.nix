{
  symlinkJoin,
  makeWrapper,
  vim,
  runCommandLocal,
}:
let
  vimRuntime = runCommandLocal "vim-runtime" { } ''
    mkdir -p $out/plugin
    ln -s ${./plugin/mappings.vim} $out/plugin/mappings.vim
    ln -s ${./vimrc} $out/vimrc
  '';
in
# TODO: --set PATH
symlinkJoin {
  name = "vim-wrapped";
  nativeBuildInputs = [ makeWrapper ];
  paths = [ vim ];
  meta.mainProgram = "vim";
  postBuild = ''
    wrapProgram $out/bin/vim \
      --add-flags "--cmd 'set rtp^=${vimRuntime}'" \
      --add-flags "-u ${vimRuntime}/vimrc"
  '';
}
