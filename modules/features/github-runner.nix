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
          common = {
            enable = true;
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
          };

          # tower serves CI for several repos. Neither user accounts nor the
          # organisations we are not admins of expose org-level runners, so
          # each repo needs its own registration. Runners are named
          # tower-<owner>-<repo>-<n>; the owner is in there because the merge
          # below is `//`, which would otherwise let two owners' same-named
          # repos silently clobber each other.
          mkRunners =
            {
              owner,
              repo,
              count,
              settings ? { },
            }:
            lib.genAttrs (map (n: "tower-${owner}-${repo}-${toString n}") (lib.range 1 count)) (
              _: common // settings // { url = "https://github.com/${owner}/${repo}"; }
            );
        in
        mkRunners {
          owner = "etrobert";
          repo = "setup";
          count = 6;
        }
        // mkRunners {
          owner = "lafraise-pro";
          repo = "app";

          # One rather than six: a pms-front check unpacks a 2.6 GB workspace
          # and runs 3489 tests.
          count = 1;

          # GitHub stamps `self-hosted`, `Linux` and `X64` onto every runner it
          # registers, and lafraise-pro/app already runs its CI on the
          # organisation's runners. Keeping those labels would make this one
          # eligible for those jobs and fail them on colleagues' pull requests;
          # without them it answers only to `runs-on: [nix]`.
          settings = {
            noDefaultLabels = true;
            extraLabels = [ "nix" ];
          };
        };

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
