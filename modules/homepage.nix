_: {
  flake.nixosModules.homepage = _: {
    services.homepage-dashboard = {
      enable = true;
      listenPort = 8082;
      # Reachable on the LAN only — the home router doesn't forward 8082.
      openFirewall = true;
      allowedHosts = "tower:8082,tower.lan:8082,192.168.0.10:8082,localhost:8082";

      settings = {
        title = "tower";
        theme = "dark";
        headerStyle = "clean";
        statusStyle = "dot";
      };

      services = [
        {
          "Personal" = [
            {
              "etiennerobert.com" = {
                href = "https://test.etiennerobert.com";
                description = "Static site";
                siteMonitor = "http://localhost/";
              };
            }
            {
              "Creatures" = {
                href = "https://creatures.etiennerobert.com";
                description = "Creatures server";
                siteMonitor = "http://localhost:3000";
              };
            }
            {
              "Countdown" = {
                href = "https://countdown.etiennerobert.com";
                description = "Static site";
              };
            }
          ];
        }
        {
          "Files" = [
            {
              "Adele" = {
                href = "https://adele.etiennerobert.com";
                description = "Filebrowser";
                siteMonitor = "http://localhost:8081";
              };
            }
            {
              "Files index" = {
                href = "https://files.etiennerobert.com";
                description = "Static file browser";
              };
            }
          ];
        }
        {
          "Home" = [
            {
              "Home Assistant" = {
                href = "http://tower:8123";
                description = "Home automation";
                siteMonitor = "http://localhost:8123";
              };
            }
          ];
        }
        {
          "System" = [
            {
              "Cockpit" = {
                href = "https://tower:9090";
                description = "Systemd units, logs, system admin";
                siteMonitor = "http://localhost:9090";
              };
            }
          ];
        }
      ];

      widgets = [
        {
          resources = {
            cpu = true;
            memory = true;
            disk = "/";
          };
        }
      ];
    };
  };
}
