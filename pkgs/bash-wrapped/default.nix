{
  inputs',
  bash,
  writeText,
  fzf,
  git,
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
in
wrapPackage {
  package = bash;
  env.INPUTRC = "${inputrc}";
  flags = [ "--rcfile ${bashrcFinal}" ];
  # Fail the build on a syntax error in our bashrc rather than at shell start-up.
  checks = [ "${bash}/bin/bash -n ${./bashrc}" ];
  inheritPath = true;
}
