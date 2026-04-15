{
  pkgs,
  # self',
  lib,
  userConfig ? ./gitconfig-user,
}:
# TODO: --set PATH
let
  deps = with pkgs; [
    # TODO: Fix this
    # Removed so that neovim-wrapped is not included on the pi
    # self'.packages.gen-commit-msg
    difftastic
    fzf
  ];
in
pkgs.symlinkJoin {
  name = "git-wrapped";
  nativeBuildInputs = with pkgs; [ makeWrapper ];
  paths = with pkgs; [ git ];
  meta.mainProgram = "git";
  postBuild = ''
    wrapProgram $out/bin/git \
      --set GIT_CONFIG_SYSTEM ${./gitconfig-system} \
      --set GIT_CONFIG_GLOBAL ${userConfig} \
      --prefix PATH : ${lib.makeBinPath deps}
  '';
}
