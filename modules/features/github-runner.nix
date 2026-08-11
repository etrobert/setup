_: {
  flake.nixosModules.githubRunner =
    {
      self,
      config,
      lib,
      pkgs,
      ...
    }:
    {
      services.github-runners =
        let
          inherit (pkgs.stdenv.hostPlatform) system;
          inherit (self.packages.${system}) ntfy-wrapped gh-wrapped;

          # tower serves CI for several of etrobert's repos. GitHub user
          # accounts have no org-level runners, so each repo needs its own
          # registration. Runners are named tower-<repo>-<n>.
          runnerCountByRepo = {
            setup = 6;
          };

          mkRunners =
            repo: count:
            lib.genAttrs (map (n: "tower-${repo}-${toString n}") (lib.range 1 count)) (_: {
              enable = true;
              url = "https://github.com/etrobert/${repo}";
              tokenFile = config.age.secrets.github-runner-token.path;
              replace = true;

              # gh (pre-authenticated as etrobert-bot) and ntfy for the
              # flake-update pipeline workflows.
              extraPackages = [
                pkgs.jq
                gh-wrapped
                ntfy-wrapped
              ];

              # The module defaults to Restart=no for persistent runners, so an
              # OOM-killed runner stays down until manually restarted.
              serviceOverrides = {
                Restart = lib.mkForce "on-failure";
                RestartSec = "10s";

                # Membership in the secret's group so gh-wrapped can read the
                # bot token (the runners are DynamicUser services).
                SupplementaryGroups = [ "github-bot-token" ];
              };
            });
        in
        lib.concatMapAttrs mkRunners runnerCountByRepo;

      age.secrets.github-runner-token.file = ../../secrets/github-runner-token.age;

      # Widen the bot token (declared in the workstation profile, owner soft)
      # to a group the runner services join, for gh-wrapped. Exposure: every
      # job on these runners can read the token — including fork-PR CI, which
      # GitHub's own secret isolation would withhold secrets from. Safe only
      # while workflow runs from fork PRs stay disabled in the repo settings.
      users.groups.github-bot-token = { };

      age.secrets.github-bot-token = {
        group = "github-bot-token";
        mode = "0440";
      };

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
        file = ../../secrets/github-runner-token.age;
        owner = "_github-runner";
      };
    };
}
