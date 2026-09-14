text=$(grim -g "$(slurp)" - | tesseract stdin stdout -l eng+fra+deu)
printf '%s' "$text" | wl-copy
notify-send -i edit-copy "Copied" "$text"
