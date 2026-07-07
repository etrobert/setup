# Self-hosted GitHub Actions runner for the etrobert/setup Nix CI workflow.
#
# Provisioning follow-ups (not covered by this config alone):
#   - Encrypt the real registration token: `agenix -e github-runner-token.age`.
#     The checked-in file is a placeholder so the flake evaluates; the runner
#     won't register until it holds a valid token.
#   - Add the `RUNNER_PROBE_TOKEN` repo Actions secret (PAT with
#     `administration:read`) so the workflow probe can see this runner.
#   - Enable "Require approval for all fork PRs" in the repo's Actions settings.
#   - `nixos-rebuild switch` on tower to bring the runner online.
#
# git and nix are on the runner's PATH by default (github-runner service
# module), so the CI checkout and `nix build` steps work without extraPackages.
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
