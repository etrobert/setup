_: {
  perSystem =
    {
      pkgs,
      lib,
      self',
      ...
    }:
    let
      makeNeovim =
        with-git-wrapped:
        let
          cfg =
            (lib.evalModules {
              specialArgs = { inherit self' pkgs with-git-wrapped; };
              # Every directory under plugins/ is one, except those listed as
              # disabled; adding a plugin means adding a directory.
              modules =
                let
                  disabled = [
                    "workspace-diagnostics" # takes a monstrous amount of ressources
                    "hardtime"
                    # TODO: Figure out when to run the banner to make sure it
                    # measures the right startup time
                    "startup-banner"
                  ];
                in
                [ ./module.nix ]
                ++ lib.pipe ./plugins [
                  builtins.readDir
                  (lib.filterAttrs (name: type: type == "directory" && !(builtins.elem name disabled)))
                  (lib.mapAttrsToList (name: _: ./plugins + "/${name}"))
                ];
            }).config;

          pbcopy = pkgs.runCommandLocal "pbcopy" { } ''
            mkdir -p $out/bin
            ln -s /usr/bin/pbcopy $out/bin/pbcopy
          '';

          pbpaste = pkgs.runCommandLocal "pbpaste" { } ''
            mkdir -p $out/bin
            ln -s /usr/bin/pbpaste $out/bin/pbpaste
          '';

          sharedDeps = with pkgs; [
            curl # used in my config
            cargo
            rustc
          ];

          darwinDeps = [
            pbcopy
            pbpaste
          ];

          linuxDeps = with pkgs; [
            wl-clipboard
            coreutils # provides cat for copying
            # Without it nvim's LSP file-watching fallback walks the whole tree on the main loop.
            inotify-tools
          ];

          path = lib.makeBinPath (
            sharedDeps
            ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin darwinDeps
            ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux linuxDeps
            ++ (lib.concatMap (plugin: plugin.extraPackages) cfg.plugins)
          );
        in
        pkgs.wrapNeovimUnstable pkgs.neovim-unwrapped {
          plugins = map (plugin: {
            inherit (plugin) plugin config;
            type = "lua";
          }) cfg.plugins;
          luaRcContent = builtins.readFile ./init.lua;
          wrapperArgs = [
            "--prefix"
            "PATH"
            ":"
            (lib.toString path)
          ];
        };
    in
    {
      packages = {
        neovim-wrapped = makeNeovim true;

        # git-wrapped pulls in gen-commit-msg, which pulls in neovim; this
        # variant breaks that cycle for gen-commit-msg's own editor.
        neovim-wrapped-without-git = makeNeovim false;
      };
    };
}
