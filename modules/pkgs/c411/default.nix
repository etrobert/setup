# Search c411's Torznab API and hand a release to transmission on charon.
_: {
  perSystem =
    { pkgs, ... }:
    {
      packages.c411 = pkgs.writeShellApplication {
        name = "c411";

        runtimeInputs = with pkgs; [
          coreutils
          curl
          transmission_4
          xmlstarlet
        ];

        inheritPath = false;

        text = /* bash */ ''
          [[ $# -gt 0 ]] || {
            echo "Usage: c411 <search terms>" >&2
            exit 1
          }

          feed=$(curl --silent --show-error --fail --get \
            --data-urlencode "apikey=$(< /run/agenix/c411-api-key)" \
            --data-urlencode "t=music" \
            --data-urlencode "q=$*" \
            https://c411.org/api/torznab)

          # unesc: xmlstarlet re-escapes & on output, which would break the URL.
          field() {
            xmlstarlet sel -N tn=http://torznab.com/schemas/2015/feed \
              --template --match '//item' --value-of "$1" --nl <<< "$feed" |
              xmlstarlet unesc
          }

          mapfile -t seeders < <(field 'tn:attr[@name="seeders"]/@value')
          mapfile -t sizes < <(field size)
          mapfile -t titles < <(field title)
          # enclosure carries the download; link is the details page.
          mapfile -t links < <(field 'enclosure/@url')

          (( ''${#titles[@]} )) || {
            echo "no results" >&2
            exit 1
          }

          for i in "''${!titles[@]}"; do
            printf '%3d  %4s seeds  %9s  %s\n' \
              "$((i + 1))" "''${seeders[i]}" "$(numfmt --to=iec "''${sizes[i]}")" "''${titles[i]}"
          done

          read -rp "download which? " n
          if ! [[ $n =~ ^[0-9]+$ ]] || (( n < 1 || n > ''${#titles[@]} )); then
            echo "not a result number" >&2
            exit 1
          fi

          transmission-remote torrents:80 --add "''${links[n - 1]}"
        '';
      };
    };
}
