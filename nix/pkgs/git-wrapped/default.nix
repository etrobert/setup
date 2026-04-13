{
  # self',
  lib,
  symlinkJoin,
  makeWrapper,
  writeText,
  git,
  difftastic,
  fzf,
  userName ? "Etienne Robert",
  userEmail ? "etiennerobert33@gmail.com",
}:
let
  gitConfig = writeText "gitconfig" ''
    [user]
      email = ${userEmail}
      name = ${userName}
    ${builtins.readFile ./.gitconfig}
  '';
in
# TODO: --set PATH
symlinkJoin {
  name = "git-wrapped";
  nativeBuildInputs = [ makeWrapper ];
  paths = [ git ];
  meta.mainProgram = "git";
  postBuild = ''
    wrapProgram $out/bin/git \
      --set GIT_CONFIG_GLOBAL ${gitConfig} \
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
