{
  pkgs,
  self',
  stdenv,
  runCommandLocal,
  neovim-unwrapped,
  wrapNeovimUnstable,
  lib,
  coreutils,
  curl,
  cargo,
  rustc,
  wl-clipboard,
  with-git-wrapped ? true,
}:
let
  cfg =
    (lib.evalModules {
      specialArgs = { inherit self' pkgs with-git-wrapped; };
      modules = [
        ./module.nix
        ./plugins/lualine
        ./plugins/octo
        ./plugins/fugitive
        ./plugins/fidget
        ./plugins/lazydev
        ./plugins/bufferline
        ./plugins/ts-autotag
        ./plugins/spider
        ./plugins/catppuccin
        ./plugins/treesj
        ./plugins/vim-tmux-navigator
        ./plugins/which-key
        ./plugins/notify
        ./plugins/conform
        ./plugins/telescope
        ./plugins/snacks
        ./plugins/copilot
        ./plugins/gitsigns
        # Disabled because this takes a monstrous amount of ressources
        # ./plugins/workspace-diagnostics
        ./plugins/lspconfig
        ./plugins/harpoon
        ./plugins/cmp
        ./plugins/treesitter
      ];
    }).config;

  pbcopy = runCommandLocal "pbcopy" { } ''
    mkdir -p $out/bin
    ln -s /usr/bin/pbcopy $out/bin/pbcopy
  '';

  pbpaste = runCommandLocal "pbpaste" { } ''
    mkdir -p $out/bin
    ln -s /usr/bin/pbpaste $out/bin/pbpaste
  '';

  path = lib.makeBinPath (
    [
      curl # used in my config
      cargo
      rustc
    ]
    ++ lib.optionals stdenv.isDarwin [
      pbcopy
      pbpaste
    ]
    ++ lib.optionals stdenv.isLinux [
      wl-clipboard
      coreutils # provides cat for copying
    ]
    ++ (lib.concatMap (plugin: plugin.extraPackages) cfg.plugins)
  );
in
wrapNeovimUnstable neovim-unwrapped {
  plugins = map (plugin: { inherit (plugin) plugin config; }) cfg.plugins;
  # TODO: Make a non dev variant
  luaRcContent = /* lua */ ''
    dofile(vim.fn.stdpath("config") .. "/init.lua")
  '';
  wrapperArgs = [
    "--set"
    "PATH"
    (lib.toString path)
  ];
}
