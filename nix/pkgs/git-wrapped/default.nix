{
  symlinkJoin,
  makeWrapper,
  git,
}:
# TODO: --set PATH
symlinkJoin {
  name = "git-wrapped";
  buildInputs = [ makeWrapper ];
  paths = [ git ];
  meta.mainProgram = "git";
  postBuild = ''
    wrapProgram $out/bin/git \
      --set GIT_CONFIG_GLOBAL ${../../../git/.gitconfig}
  '';
}
