{
  inputs',
  bash,
  writeText,
  fzf,
  git,
  runCommandLocal,
  wrapPackage,
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

  # Validate the bashrc at build time.
  _checks = runCommandLocal "bash-config-check" { } ''
    ${bash}/bin/bash -n ${./bashrc}
    mkdir $out
  '';
in
wrapPackage {
  package = bash;
  # _checks has an empty output; including it forces the syntax check to run.
  extraPaths = [ _checks ];
  env.INPUTRC = inputrc;
  flags = [ "--rcfile ${bashrcFinal}" ];
}
