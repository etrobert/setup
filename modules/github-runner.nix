# Self-hosted GitHub Actions runner for the etrobert/setup CI.
_: {
  flake.nixosModules.githubRunner =
    { config, ... }:
    {
      services.github-runners.tower = {
        enable = true;
        url = "https://github.com/etrobert/setup";
        tokenFile = config.age.secrets.github-runner-token.path;
        replace = true;
      };

      age.secrets.github-runner-token.file = ../secrets/github-runner-token.age;
    };
}
