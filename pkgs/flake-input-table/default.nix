_: {
  perSystem =
    { pkgs, ... }:
    {
      packages.flake-input-table = pkgs.writeShellApplication {
        name = "flake-input-table";
        runtimeInputs = [ pkgs.jq ];
        inheritPath = false;
        text = builtins.readFile ./flake-input-table.sh;
      };
    };
}
