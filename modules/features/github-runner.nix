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
          owner = "etrobert";
          repo = "event-sourcing-demo";
          count = 1;
        }
        // mkRunners {
          owner = "lafraise-pro";
          repo = "app";
          # Times nix-fast-build's --max-jobs 4 in the app's workflow: eight
          # node_modules writes at once is what the disk sustains.
          count = 2;

          # GitHub stamps `self-hosted`, `Linux` and `X64` onto every runner it
          # registers, and lafraise-pro/app already runs its CI on the
          # organisation's runners. Keeping those labels would make this one
          # eligible for those jobs and fail them on colleagues' pull requests;
          # without them it answers only to `runs-on: [nix]`.
          settings = {
            # A fine-grained PAT carries exactly one resource owner, so this
            # cannot share the token the etrobert runners use.
            tokenFile = config.age.secrets.lafraise-runner-token.path;

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

      # Per build. A single tsc or next build otherwise takes every thread;
      # how many builds run at once is the runner count times the workflow's
      # --max-jobs, since max-jobs binds per client, not per daemon.
      nix.settings.cores = 2;

      # Every check writes ~3 GB of node_modules it never reads again; on the
      # NVMe eight of them at once pinned it (65% iowait), in RAM the same
      # install ran 4.8 s against 13.1 s. Nix 2.26+ builds under
      # /nix/var/nix/builds, not /tmp. Sized for four builds at a time on this
      # 60 GB workstation; a build over the cap fails, it does not spill.
      fileSystems."/nix/var/nix/builds" = {
        fsType = "tmpfs";
        options = [
          "size=12G"
          "mode=0755"
        ];
      };

      age.secrets.github-runner-token.file = ../../secrets/github-runner-token.age;
      age.secrets.lafraise-runner-token.file = ../../secrets/lafraise-runner-token.age;

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
