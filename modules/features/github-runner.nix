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

              # gh for the flake-update pipeline workflows.
              extraPackages = [
                pkgs.jq
                pkgs.gh
              ];

              # The module defaults to Restart=no for persistent runners, so an
              # OOM-killed runner stays down until manually restarted.
              serviceOverrides = {
                Restart = lib.mkForce "on-failure";
                RestartSec = "10s";

                # Write access to the CI assets dir (below); ProtectSystem=strict
                # makes the rest of the filesystem read-only regardless of the
                # group, so the sandbox needs the explicit hole too.
                SupplementaryGroups = [ "ci-assets" ];
                ReadWritePaths = [ "/srv/files/ci" ];
              };
            });
        in
        lib.concatMapAttrs mkRunners runnerCountByRepo;

      # Images for flake-update PR bodies (closure diffs), served publicly as
      # files.etiennerobert.com/ci/ (vhost in profiles/server.nix). Dedicated
      # group rather than "users": runners execute fork-PR code and must not
      # gain write access to the rest of /srv/files. Entries expire like the
      # temp drop-zone; images in old PRs 404 after that.
      users.groups.ci-assets = { };
      systemd.tmpfiles.settings.ci-assets."/srv/files/ci".d = {
        user = "soft";
        group = "ci-assets";
        mode = "2775";
        age = "90d";
      };

      age.secrets.github-runner-token.file = ../../secrets/github-runner-token.age;

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

      power.sleep.computer = "never";

      # The runner daemon runs entirely as _github-runner and reads the
      # token itself, so agenix must chown it off the default root:0400.
      age.secrets.github-runner-token = {
        file = ../../secrets/github-runner-token.age;
        owner = "_github-runner";
      };
    };
}
