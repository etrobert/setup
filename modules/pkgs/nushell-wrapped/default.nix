_: {
  perSystem =
    {
      pkgs,
      lib,
      inputs',
      self',
      ...
    }:
    {
      packages.nushell-wrapped =
        let
          pronto = lib.getExe inputs'.pronto.packages.default;

          prompt = pkgs.writeText "prompt.nu" /* nu */ ''
            $env.PROMPT_COMMAND = {|| ${pronto} $env.LAST_EXIT_CODE --nu }
            $env.PROMPT_COMMAND_RIGHT = {||
              # CMD_DURATION_MS holds "0823" until the first command has run.
              let duration = if $env.CMD_DURATION_MS == "0823" { [] } else { [$"--cmd-duration=($env.CMD_DURATION_MS)"] }
              ${pronto} $env.LAST_EXIT_CODE --rprompt --nu ...$duration
            }
          '';

          autoload =
            pkgs.runCommand "nushell-autoload"
              {
                # atuin creates its config dir even for `init`.
                nativeBuildInputs = [ pkgs.writableTmpDirAsHomeHook ];
              }
              /* bash */ ''
                mkdir $out
                {
                  cat ${./config.nu} ${prompt}
                  ${self'.packages.fzf-wrapped}/bin/fzf --nushell
                  ${self'.packages.atuin-wrapped}/bin/atuin init nu
                  ${pkgs.zoxide}/bin/zoxide init nushell
                } > $out/init.nu
              '';
        in
        self'.legacyPackages.wrapPackage {
          package = pkgs.nushell;
          # Unlike --config, autoload is skipped by `nu -c` and scripts.
          env.NU_VENDOR_AUTOLOAD_DIR = autoload;
          inheritPath = true;
        };
    };
}
