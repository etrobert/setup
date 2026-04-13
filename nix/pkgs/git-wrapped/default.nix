{
  # self',
  lib,
  symlinkJoin,
  makeWrapper,
  git,
  difftastic,
  fzf,
  userConfig ? ./gitconfig-user,
}:
# TODO: --set PATH
symlinkJoin {
  name = "git-wrapped";
  nativeBuildInputs = [ makeWrapper ];
  paths = [ git ];
  meta.mainProgram = "git";
  postBuild = ''
    wrapProgram $out/bin/git \
      --set GIT_CONFIG_SYSTEM ${./gitconfig-system} \
      --set GIT_CONFIG_GLOBAL ${userConfig} \
      --prefix PATH :${
        lib.makeBinPath [
          # TODO: Fix this
          # Removed so that neovim-wrapped is not included on the pi
          # self'.packages.gen-commit-msg
          difftastic
          fzf
        ]
      }
  
'';
}
