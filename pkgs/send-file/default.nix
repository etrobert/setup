_: {
  perSystem =
    { pkgs, self', ... }:
    {
      packages.send-file = pkgs.writeShellApplication {
        name = "send-file";
        runtimeInputs = [ self'.packages.ntfy-wrapped ];
        inheritPath = false;
        text = builtins.readFile ./send-file.sh;
      };
    };
}
