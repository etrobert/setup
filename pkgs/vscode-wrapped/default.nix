{ vscode-with-extensions, vscode-extensions, ... }:
vscode-with-extensions.override {
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
}
