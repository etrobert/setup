{
  vscode-with-extensions,
  vscode-extensions,
  symlinkJoin,
  makeWrapper,
  writeShellScript,
  stdenv,
  ...
}:
let
  vscode = vscode-with-extensions.override {
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
      # yinfei.luahelper
    ];
  };

  setupConfig = writeShellScript "vscode-setup-config" ''
    if [ "$(uname)" = "Darwin" ]; then
      dir="$HOME/Library/Application Support/Code/User"
    else
      dir="$HOME/.config/Code/User"
    fi
    mkdir -p "$dir"
    ln -sf '${./settings.json}' "$dir/settings.json"
    ln -sf '${./keybindings.json}' "$dir/keybindings.json"
  '';
in
symlinkJoin {
  name = "vscode-wrapped";
  nativeBuildInputs = [ makeWrapper ];
  paths = [ vscode ];
  postBuild = ''
    wrapProgram $out/bin/code \
      --run ${setupConfig}
  '';
}
