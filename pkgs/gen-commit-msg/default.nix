_: {
  perSystem =
    { pkgs, self', ... }:
    {
      packages.gen-commit-msg = pkgs.writeShellApplication {
        name = "gen-commit-msg";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.curl
          (self'.packages.neovim-wrapped.override { with-git-wrapped = false; }) # for editing the commit
          pkgs.git
          pkgs.gnused
          pkgs.jq
        ];
        inheritPath = false;
        text = builtins.readFile ./gen-commit-msg.sh;
      };
    };
}
