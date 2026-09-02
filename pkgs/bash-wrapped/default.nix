_: {
  perSystem =
    {
      config,
      pkgs,
      inputs',
      self',
      ...
    }:
    {
      packages.bash-wrapped =
        let
          pronto = "${inputs'.pronto.packages.default}/bin/pronto";

          bashrcFinal = pkgs.writeText "bashrc" /* bash */ ''
            source ${./bashrc}

            source ${pkgs.git}/share/git/contrib/completion/git-completion.bash

            PS1='$(${pronto} $?)'

            source <(${self'.packages.fzf-wrapped}/bin/fzf --bash)
          '';

          inputrc = pkgs.writeText "inputrc" (builtins.readFile ./inputrc);
        in
        config.lib.wrapPackage {
          package = pkgs.bash;
          env.INPUTRC = "${inputrc}";
          flags = [ "--rcfile ${bashrcFinal}" ];
          # Fail the build on a syntax error in our bashrc rather than at shell start-up.
          checks = [ "${pkgs.bash}/bin/bash -n ${./bashrc}" ];
          inheritPath = true;
        };
    };
}
