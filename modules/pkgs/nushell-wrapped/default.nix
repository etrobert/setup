_: {
  perSystem =
    { pkgs, self', ... }:
    {
      packages.nushell-wrapped =
        let
          autoload =
            pkgs.runCommand "nushell-autoload"
              {
                # atuin creates its config dir even for `init`.
                nativeBuildInputs = [ pkgs.writableTmpDirAsHomeHook ];
              }
              /* bash */ ''
                mkdir $out
                {
                  cat ${./config.nu}
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
