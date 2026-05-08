{
  inputs',
  symlinkJoin,
  makeWrapper,
  bash,
  writeText,
  fzf,
  git,
  runCommandLocal,
}:
let
  pronto = "${inputs'.pronto.packages.default}/bin/pronto";

  bashrcFinal = writeText "bashrc" /* bash */ ''
    source ${./bashrc}

    source ${git}/share/git/contrib/completion/git-completion.bash

    PS1='$(${pronto} $?)'

    source <(${fzf}/bin/fzf --bash)
  '';

  inputrc = writeText "inputrc" (builtins.readFile ./inputrc);

  _checks = runCommandLocal "bash-config-check" { } ''
    ${bash}/bin/bash -n ${./bashrc}
    mkdir $out
  '';
in
symlinkJoin {
  name = "bash-wrapped";
  nativeBuildInputs = [ makeWrapper ];
  paths = [
    bash
    _checks
  ];
  meta.mainProgram = "bash";
  postBuild = ''
    wrapProgram $out/bin/bash \
      --set INPUTRC ${inputrc} \
      --add-flags "--rcfile ${bashrcFinal}"
  '';
}
