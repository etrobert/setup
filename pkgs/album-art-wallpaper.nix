{
  writeShellApplication,
  playerctl,
  curl,
  awww,
}:
writeShellApplication {
  name = "album-art-wallpaper";
  runtimeInputs = [
    playerctl
    curl
    awww
  ];
  text = ''
    playerctl --follow metadata --format '{{mpris:artUrl}}' | while read -r url; do
      [ -z "$url" ] && continue
      curl -sL "$url" -o /tmp/albumart.jpg
      awww img /tmp/albumart.jpg
    done
  '';
}
