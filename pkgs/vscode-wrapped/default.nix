{
  claude-code-wrapped,
  lib,
  vscode,
  vscode-with-extensions,
  vscode-extensions,
  ...
}:
let
  # The extension exec's resources/native-binary/claude directly rather than
  # resolving `claude` from PATH (extension.js: z_r), so replacing that file is
  # what makes its sessions run our wrapper — CLAUDE_CONFIG_DIR, --plugin-dir
  # and the hook PATH — instead of reading ~/.claude. Dropping the bundled copy
  # also takes 324 MB out of the closure. rm fails the build if upstream moves
  # the path, which nixpkgs pins too (passthru.tests.bundled-claude-runs).
  claude-code-extension = vscode-extensions.anthropic.claude-code.overrideAttrs (old: {
    postInstall = (old.postInstall or "") + ''
      ext=$out/share/vscode/extensions/anthropic.claude-code
      rm "$ext/resources/native-binary/claude"
      ln -s ${lib.getExe claude-code-wrapped} "$ext/resources/native-binary/claude"
    '';
  });
in
vscode-with-extensions.override {
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
    claude-code-extension
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
    # yinfei.luahelper
  ];
}
