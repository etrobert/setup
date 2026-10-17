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
              echo "Usage: add-asset <url>" >&2
              exit 1
            }

            [[ $# -eq 1 ]] || usage

            url="$1"
            dest_dir="$HOME/sync/doc/assets"

            filename=$(basename "$url" | cut -d'?' -f1)
            [[ -n "$filename" ]] || {
              echo "Could not derive filename from URL" >&2
              exit 1
            }

            dest="$dest_dir/$filename"

            echo "Downloading $url -> $dest"
            curl -fsSL "$url" -o "$dest"

            printf '%s' "$dest" | ${if pkgs.stdenv.hostPlatform.isDarwin then "pbcopy" else "wl-copy"}

            echo "Copied to clipboard: $dest"
          '';
        };
    };
}
