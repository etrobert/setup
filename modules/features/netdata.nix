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

      # The default build sets `withCloudUi = false`, which leaves
      # share/netdata/web/ holding only the swagger files — every dashboard URL
      # answers "File does not exist, or is not accessible". Enabling it pulls
      # in the Netdata Cloud UI, which is unfree and non-redistributable.
      allowedUnfreePackages = [ "netdata" ];

      services.netdata = {
        enable = true;
        package = pkgs.netdata.override { withCloudUi = true; };
        config.web."bind to" = "localhost";
        extraNdsudoPackages = [
          pkgs.smartmontools
          pkgs.nvme-cli
        ];
      };
    };
}
