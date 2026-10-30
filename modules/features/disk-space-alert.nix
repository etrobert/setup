# Fails while / runs low, so ntfy-failure-alerts posts the message below.
_: {
  flake.nixosModules.disk-space-alert = _: {
    systemd.services.disk-space-alert = {
      startAt = "hourly";

      # MB: df rounds up, so --block-size=G would report 2.1 GB as 3.
      script = /* bash */ ''
        available=$(df --output=avail --block-size=M / | tail --lines 1 | tr --delete ' M')
        if ((available < 3000)); then
          echo "Only $available MB available on /"
          exit 1
        fi
      '';

      serviceConfig.Type = "oneshot";
    };
  };
}
