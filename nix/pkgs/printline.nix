{ writeShellApplication, bat }:
writeShellApplication {
  name = "printline";
  runtimeInputs = [ bat ];
  inheritPath = false;
  text = ''
    for _ in {1..80}; do echo -n '-'; done

    echo
  '';
}
