# Continuous system metrics, kept mainly for per-disk throughput, latency and
# temperature history — smartd only alerts, it records nothing over time.
#
# Bound to localhost; tsnsrv publishes it on the tailnet as `metrics`.
_: {
  flake.nixosModules.netdata =
    { pkgs, ... }:
    {
      # The four SATA SSDs expose no temperature to any collector until
      # drivetemp binds them.
      boot.kernelModules = [ "drivetemp" ];

      services.netdata = {
        enable = true;
        config.web."bind to" = "localhost";
        extraNdsudoPackages = [
          pkgs.smartmontools
          pkgs.nvme-cli
        ];
      };
    };
}
