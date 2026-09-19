# Push GitHub notifications on pull requests in other people's repos to ntfy,
# so review comments and merges are not lost in the web inbox.
{ self, ... }:
{
  perSystem =
    { pkgs, self', ... }:
    {
      packages.github-pr-watch = pkgs.writeShellApplication {
        name = "github-pr-watch";

        runtimeInputs = [
          pkgs.coreutils
          pkgs.gh
          pkgs.jq
          self'.packages.ntfy-wrapped
        ];

        inheritPath = false;
        text = builtins.readFile ./watch.sh;
      };
    };

  flake.nixosModules.githubPrWatch =
    { pkgs, lib, ... }:
    {
      systemd = {
        services.github-pr-watch = {
          description = "Notify about GitHub pull request activity in other people's repos";

          serviceConfig = {
            Type = "oneshot";
            # The notifications API accepts only classic tokens; rather than
            # mint one, reuse gh's login.
            User = "soft";
            ExecStart = lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.github-pr-watch;
          };
        };

        timers.github-pr-watch = {
          description = "Schedule the GitHub pull request notification poll";
          wantedBy = [ "timers.target" ];
          timerConfig.OnCalendar = "*:0/5";
        };
      };
    };
}
