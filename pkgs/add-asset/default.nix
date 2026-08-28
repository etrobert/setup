_: {
  perSystem =
    { pkgs, lib, ... }:
    {
      packages.add-asset =
        let
          pbcopy = pkgs.runCommandLocal "pbcopy" { } ''
            mkdir -p $out/bin
            ln -s /usr/bin/pbcopy $out/bin/pbcopy
          '';
        in
        pkgs.writeShellApplication {
          name = "add-asset";
          runtimeInputs =
            with pkgs;
            [
              coreutils
              curl
            ]
            ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [ pbcopy ]
            ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.wl-clipboard ];
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
        };
    };
}
