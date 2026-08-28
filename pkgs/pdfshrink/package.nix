{ writeShellApplication, ghostscript }:
writeShellApplication {
  name = "pdfshrink";
  runtimeInputs = [ ghostscript ];
  inheritPath = false;
  text = ''
    if [ "$#" -ne 1 ]; then
      echo "Usage: pdfshrink <input.pdf>"
      exit 1
    fi

    input="$1"
    output="''${input%.pdf}-compressed.pdf"

    gs -sDEVICE=pdfwrite \
      -dCompatibilityLevel=1.4 \
      -dPDFSETTINGS=/ebook \
      -dNOPAUSE -dQUIET -dBATCH \
      -sOutputFile="$output" \
      "$input"

    echo "Created $output"
  '';
}
