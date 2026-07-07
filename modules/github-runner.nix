# Self-hosted GitHub Actions runner for the etrobert/setup CI. nix and git are
# already on the runner's PATH (github-runner module), so the checkout and
# `nix build` steps need no extraPackages.
_:
{
  flake.nixosModules.githubRunner =
    { config, ... }:
    {
      services.github-runners.tower = {
        enable = true;
        url = "https://github.com/etrobert/setup";
        tokenFile = config.age.secrets.github-runner-token.path;
        extraLabels = [ "tower" ];
        replace = true;
      };

      age.secrets.github-runner-token.file = ../secrets/github-runner-token.age;
    };
}
