_: {
  perSystem =
    { pkgs, ... }:
    {
      packages.printline = pkgs.writeShellApplication {
        name = "printline";
        inheritPath = false;
        text = ''
          for _ in {1..80}; do echo -n '-'; done

          echo
        '';
      };
    };
}
