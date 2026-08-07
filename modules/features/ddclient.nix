_: {
  flake.nixosModules.ddclient =
    { config, ... }:
    {
      services.ddclient = {
        enable = true;
        protocol = "namecheap";
        server = "dynamicdns.park-your-domain.com";
        username = "etiennerobert.com";
        passwordFile = config.age.secrets.ddclient-password-etiennerobert-com.path;
        domains = [
          "test"
          "creatures"
          "countdown"
          "files"
          "adele"
          "umami"
          "images"
          "rift"
          "rack"
        ];
        interval = "5min";
        usev6 = "no";
        usev4 = "webv4";
      };

      # ddclient's ExecStartPre resolves its DynamicUser name through NSS, which only
      # works while nsncd is up. nsncd kills itself when a nixos-rebuild switch stalls
      # activation past its handoff timeout, and a switch restarting ddclient in that
      # window leaves the config unwritten. Retrying rides out the ~3s nsncd restart.
      # RestartSec must stay well under StartLimitIntervalUSec / StartLimitBurst (10s / 5)
      # so a genuinely broken ddclient still exhausts the limit and trips OnFailure=.
      systemd.services.ddclient.serviceConfig = {
        Restart = "on-failure";
        RestartSec = 2;
      };

      age.secrets.ddclient-password-etiennerobert-com.file = ../../secrets/ddclient-password-etiennerobert-com.age;
    };
}
