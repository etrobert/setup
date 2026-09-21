_: {
  perSystem =
    { pkgs, ... }:
    let
      # Node ships no declarations; only the type-check needs these
      typesNode = pkgs.fetchzip {
        url = "https://registry.npmjs.org/@types/node/-/node-24.9.2.tgz";
        hash = "sha256-eDkcBSekMHNcDc4p6W2BJqfi1VLg9kv/i68cL5TGcek=";
      };

      # tsc checks the types at build time; Node strips them at run time,
      # keyed on the .mts suffix of the output path
      script =
        pkgs.runCommand "nix-dead-packages.mts"
          {
            nativeBuildInputs = [ pkgs.typescript ];
          }
          ''
            mkdir types
            ln --symbolic ${typesNode} types/node
            # skipLibCheck: @types/node imports undici-types, which is not fetched
            tsc --noEmit --strict --skipLibCheck --module nodenext \
              --typeRoots types --types node ${./nix-dead-packages.mts}
            cp ${./nix-dead-packages.mts} "$out"
          '';
    in
    {
      packages.nix-dead-packages = pkgs.writeShellApplication {
        name = "nix-dead-packages";
        runtimeInputs = with pkgs; [
          git
          nix
          nodejs-slim
        ];
        inheritPath = false;
        text = "exec node ${script}";
      };
    };
}
