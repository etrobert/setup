_: {
  flake.nixosModules.githubRunner =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      services.github-runners =
        let
          # tower serves CI for several of etrobert's repos. GitHub user
          # accounts have no org-level runners, so each repo needs its own
          # registration; one entry per repo, prefix → runner count.
          reposByRunnerCount = {
            tower = {
              repo = "setup";
              count = 6;
            };
            countdown = {
              repo = "countdown";
              count = 2;
            };
          };

          mkRunners =
            prefix:
            { repo, count }:
            lib.genAttrs (map (n: "${prefix}-${toString n}") (lib.range 1 count)) (_: {
              enable = true;
              url = "https://github.com/etrobert/${repo}";
              tokenFile = config.age.secrets.github-runner-token.path;
              replace = true;
              extraPackages = [ pkgs.jq ];

              # The module defaults to Restart=no for persistent runners, so an
              # OOM-killed runner stays down until manually restarted.
              serviceOverrides = {
                Restart = lib.mkForce "on-failure";
                RestartSec = "10s";
              };
            });
        in
        lib.concatMapAttrs mkRunners reposByRunnerCount;

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
