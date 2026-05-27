file=$1
if [ -z "$file" ] || [ ! -f "$file" ]; then
  exit 0
fi

case $file in
  *.md) prettier --write "$file" ;;
esac
