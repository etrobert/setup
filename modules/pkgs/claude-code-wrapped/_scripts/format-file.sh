file=$1
if [ ! -f "$file" ]; then
  exit 0
fi

case $file in
*.lua) stylua "$file" ;;
*.js | *.jsx | *.ts | *.tsx | *.json | *.jsonc | *.html | *.md | *.css | *.yaml | *.yml)
  prettier --write "$file"
  ;;
# Conform uses shiftwidth and expandtab settings to feed --indent which we're kind of replicating here
# Source: https://github.com/stevearc/conform.nvim/blob/master/lua/conform/formatters/shfmt.lua
*.sh | *.bash | *.zsh) shfmt --write --indent 2 "$file" ;;
*.rs) rustfmt "$file" ;;
*.toml) taplo fmt "$file" ;;
*.py) isort "$file" && black "$file" ;;
*.nix) nixfmt "$file" ;;
esac
