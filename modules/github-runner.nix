# Self-hosted GitHub Actions runners for the etrobert/setup CI.
# NixOS: four runners so the workflow's self-hosted jobs (check + the
# three NixOS host builds) can run concurrently; one runner executes
# one job at a time. Darwin: a single runner on aaron for its own
# darwin build, with a hosted fallback when the laptop is asleep.
_: {
  flake.nixosModules.githubRunner =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      services.github-runners = lib.genAttrs [ "tower" "tower-2" "tower-3" "tower-4" ] (_: {
        enable = true;
        url = "https://github.com/etrobert/setup";
        tokenFile = config.age.secrets.github-runner-token.path;
        replace = true;
        extraPackages = [ pkgs.jq ];
      });

      age.secrets.github-runner-token.file = ../secrets/github-runner-token.age;

      # Run aarch64 builds (pi's CI job) via QEMU user emulation.
      boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
    };

  flake.darwinModules.githubRunner =
    { config, ... }:
    {
      services.github-runners.aaron = {
        enable = true;
        url = "https://github.com/etrobert/setup";
        tokenFile = config.age.secrets.github-runner-token.path;
        replace = true;
      };

      # The runner daemon runs entirely as _github-runner and reads the
      # token itself, so agenix must chown it off the default root:0400.
      age.secrets.github-runner-token = {
        file = ../secrets/github-runner-token.age;
        owner = "_github-runner";
      };
    };
}
