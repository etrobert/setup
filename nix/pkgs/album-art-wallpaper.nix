{
  writeShellApplication,
  playerctl,
  curl,
  hyprland,
}:
writeShellApplication {
  name = "album-art-wallpaper";
  runtimeInputs = [
    playerctl
    curl
    hyprland
  ];
  text = ''
    playerctl --follow metadata --format '{{mpris:artUrl}}' | while read -r url; do
      [ -z "$url" ] && continue
      curl -sL "$url" -o /tmp/albumart.jpg
      hyprctl hyprpaper wallpaper ",/tmp/albumart.jpg"
    done
  '';
}
