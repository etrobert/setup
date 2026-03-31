{
  stdenv,
  lib,
  coreutils,
  curl,
  writeShellApplication,
  wl-clipboard,
  runCommandLocal,
}:
let
  pbcopy = runCommandLocal "pbcopy" { } ''
    mkdir -p $out/bin
    ln -s /usr/bin/pbcopy $out/bin/pbcopy
  '';
in
writeShellApplication {
  name = "add-asset";
  runtimeInputs = [
    coreutils
    curl
  ]
  ++ lib.optionals stdenv.isDarwin [ pbcopy ]
  ++ lib.optionals stdenv.isLinux [ wl-clipboard ];
  inheritPath = false;
  text = ''
    usage() {
      echo "Usage: doc-add-image <url>" >&2
      exit 1
    }

    [[ $# -eq 1 ]] || usage

    url="$1"
    dest_dir="$HOME/sync/doc/assets"

    # Derive filename from URL, stripping query strings
    filename=$(basename "$url" | cut -d'?' -f1)
    [[ -n "$filename" ]] || {
      echo "Could not derive filename from URL" >&2
      exit 1
    }

    dest="$dest_dir/$filename"

    echo "Downloading $url -> $dest"
    curl -fsSL "$url" -o "$dest"

    # Copy path to clipboard (Wayland or macOS)
    if command -v wl-copy &>/dev/null; then
      printf '%s' "$dest" | wl-copy
    elif command -v pbcopy &>/dev/null; then
      printf '%s' "$dest" | pbcopy
    else
      echo "Warning: no clipboard tool found (wl-copy or pbcopy)" >&2
    fi

    echo "Copied to clipboard: $dest"
  '';
}
