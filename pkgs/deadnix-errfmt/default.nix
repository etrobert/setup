_: {
  perSystem =
    { pkgs, ... }:
    {
      packages.deadnix-errfmt = pkgs.writeShellApplication {
        name = "deadnix-errfmt";
        runtimeInputs = with pkgs; [
          deadnix
          jq
        ];
        inheritPath = false;
        text = ''
          deadnix --output-format json "$@" | \
            jq -r '.file as $f | .results[] | $f + ">" + (.line|tostring) + ":" + (.column|tostring) + ":W:0:" + .message'
        '';
      };
    };
}
