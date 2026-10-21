_: {
  flake.nixosModules.github-runner =
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
            tokenFile = config.sops.secrets.github-runner-token.path;
            replace = true;

            extraPackages = with pkgs; [
              jq
              gh
              curl
            ];

            # Each runner is its own DynamicUser, so the shared group grants write access
            serviceOverrides = {
              SupplementaryGroups = [ "ci-roots" ];
              ReadWritePaths = [ "/var/lib/ci-roots" ];
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
        };

      sops.secrets.github-runner-token.sopsFile = ../../secrets/workstations.yaml;

      # main's CI out-links its closures here, keeping them from the nightly GC
      users.groups.ci-roots = { };
      systemd.tmpfiles.rules = [ "d /var/lib/ci-roots 0775 root ci-roots -" ];

      # Run aarch64 builds (pi's CI job) via QEMU user emulation.
      boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
    };

  flake.darwinModules.github-runner =
    { config, ... }:
    {
      services.github-runners.aaron = {
        enable = true;
        url = "https://github.com/etrobert/setup";
        tokenFile = config.sops.secrets.github-runner-token.path;
        replace = true;
      };

      power.sleep.computer = "never";

      # The runner daemon runs entirely as _github-runner and reads the
      # token itself, so sops-nix must chown it off the default root:0400.
      sops.secrets.github-runner-token = {
        sopsFile = ../../secrets/workstations.yaml;
        owner = "_github-runner";
      };
    };
}
