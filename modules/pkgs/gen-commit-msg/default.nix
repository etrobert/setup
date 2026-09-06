_: {
  perSystem =
    { pkgs, self', ... }:
    {
      packages.gen-commit-msg = pkgs.writeShellApplication {
        name = "gen-commit-msg";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.curl
          self'.packages.neovim-wrapped-without-git # for editing the commit
          pkgs.git
          pkgs.gnused
          pkgs.jq
        ];
        inheritPath = false;
        text = builtins.readFile ./gen-commit-msg.sh;
      };
    };
}
