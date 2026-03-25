{ pkgs }:
pkgs.writeShellApplication {
  name = "printline";
  runtimeInputs = with pkgs; [ bat ];
  inheritPath = false;
  text = ''
    for _ in {1..80}; do echo -n '-'; done

    echo
  '';
}
