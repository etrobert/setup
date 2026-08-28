_: {
  perSystem =
    { pkgs, self', ... }:
    {
      packages.git-find-commit = pkgs.writeShellApplication {
        name = "git-find-commit";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.git
          self'.packages.fzf-wrapped
          pkgs.findutils # xargs
        ];
        inheritPath = false;
        text = builtins.readFile ./git-find-commit.sh;
      };
    };
}
