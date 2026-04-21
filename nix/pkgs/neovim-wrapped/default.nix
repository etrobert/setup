{
  pkgs,
  self',
  lib,
  with-git-wrapped ? true,
}:
let
  cfg =
    (lib.evalModules {
      specialArgs = { inherit self' pkgs with-git-wrapped; };
      modules = [
        ./module.nix
        ./plugins/octo
        ./plugins/fugitive
        ./plugins/fidget
        ./plugins/lazydev
        ./plugins/bufferline
        ./plugins/spider
        ./plugins/catppuccin
        ./plugins/treesj
        ./plugins/vim-tmux-navigator
        ./plugins/which-key
        ./plugins/conform
        ./plugins/telescope
        ./plugins/snacks
        ./plugins/copilot
        ./plugins/gitsigns
        # Disabled because this takes a monstrous amount of ressources
        # ./plugins/workspace-diagnostics
        ./plugins/lspconfig
        ./plugins/harpoon
        ./plugins/treesitter
        ./plugins/surround
        # ./plugins/hardtime
        ./plugins/matchup
        ./plugins/statusline
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
  ];

  path = lib.makeBinPath (
    sharedDeps
    ++ lib.optionals pkgs.stdenv.isDarwin darwinDeps
    ++ lib.optionals pkgs.stdenv.isLinux linuxDeps
    ++ (lib.concatMap (plugin: plugin.extraPackages) cfg.plugins)
  );
in
pkgs.wrapNeovimUnstable pkgs.neovim-unwrapped {
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
