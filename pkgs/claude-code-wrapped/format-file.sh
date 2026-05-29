file=$1
if [ ! -f "$file" ]; then
	exit 0
fi

case $file in
*.lua) stylua "$file" ;;
*.js | *.jsx | *.ts | *.tsx | *.json | *.jsonc | *.html | *.md | *.css | *.yaml | *.yml)
	prettier --write "$file"
	;;
*.sh | *.bash | *.zsh) shfmt -w "$file" ;;
*.rs) rustfmt "$file" ;;
*.py) isort "$file" && black "$file" ;;
*.nix) nixfmt "$file" ;;
esac
