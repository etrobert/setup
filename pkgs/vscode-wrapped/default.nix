{
  vscode,
  vscode-with-extensions,
  vscode-extensions,
  wrapPackage,
  nixd,
  nixfmt,
  ...
}:
wrapPackage {
  package = vscode-with-extensions.override {
    # Point VS Code at an in-repo, writable user-data dir (settings.json and
    # keybindings.json live under ./user-data/User/). Threading the flag through
    # nixpkgs' own commandLineArgs makes it land in every entry-point wrapper the
    # build creates — bin/code on Linux/macOS and the .app Electron on macOS — so
    # terminal, .desktop, and Dock launches all pick it up.
    #
    # commandLineArgs is escapeShellArg'd at build time, but makeWrapper writes the
    # flag unquoted into the runtime wrapper, so $HOME expands at launch (verified).
    # ~/work/setup/main is the main worktree on both Linux and macOS, mirroring how
    # claude-code-wrapped points CLAUDE_CONFIG_DIR at $HOME/work/setup/main.
    vscode = vscode.override {
      commandLineArgs = " --user-data-dir=$HOME/work/setup/main/pkgs/vscode-wrapped/user-data";
    };

    vscodeExtensions = with vscode-extensions; [
      eamodio.gitlens
      oderwat.indent-rainbow
      pkief.material-icon-theme
      vscodevim.vim
      aaron-bond.better-comments
      # github.copilot-chat
      usernamehw.errorlens
      ms-vsliveshare.vsliveshare

      # JavaScript/TypeScript
      esbenp.prettier-vscode
      dbaeumer.vscode-eslint
      yoavbls.pretty-ts-errors
      bradlc.vscode-tailwindcss

      # Other Languages
      davidanson.vscode-markdownlint
      rust-lang.rust-analyzer
      jnoortheen.nix-ide
      # yinfei.luahelper
    ];
  };

  # The integrated terminal and every extension that shells out (git, node,
  # eslint) need the caller's PATH intact.
  inheritPath = true;

  # nix-ide spawns these by name. Scoping them here rather than adding them to
  # the workstation profile keeps them off the interactive shell's PATH.
  runtimeInputs = [
    nixd
    nixfmt
  ];
}
