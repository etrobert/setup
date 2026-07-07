# Self-hosted GitHub Actions runners for the etrobert/setup CI.
# Four runners so the workflow's self-hosted jobs (check + the three
# NixOS host builds) can run concurrently; one runner executes one job
# at a time.
_: {
  flake.nixosModules.githubRunner =
    { config, lib, ... }:
    {
      services.github-runners = lib.genAttrs [ "tower" "tower-2" "tower-3" "tower-4" ] (_: {
        enable = true;
        url = "https://github.com/etrobert/setup";
        tokenFile = config.age.secrets.github-runner-token.path;
        replace = true;
      });

      age.secrets.github-runner-token.file = ../secrets/github-runner-token.age;

      # Run aarch64 builds (pi's CI job) via QEMU user emulation.
      boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
    };
}
