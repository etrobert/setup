{ self, inputs, ... }:
let
  official-plugins = inputs.noctalia-official-plugins;
  community-plugins = inputs.noctalia-community-plugins;

  makeNoctalia =
    {
      pkgs,
      lib,
      vramWidget,
      idleLock,
    }:
    let
      plugins = ./plugins;

      wallpaper = ./saint-levant.jpg;

      configHome = pkgs.runCommand "noctalia-config-home" { } ''
        mkdir -p $out/noctalia
        substitute ${./config.toml} $out/noctalia/config.toml \
          --replace-fail '@plugins@' '${plugins}' \
          --replace-fail '@official-plugins@' '${official-plugins}' \
          --replace-fail '@community-plugins@' '${community-plugins}' \
          --replace-fail '@wallpaper@' '${wallpaper}' \
          --replace-fail '@vram-widget@' '${lib.optionalString vramWidget ''"vram",''}' \
          --replace-fail '@idle-lock@' '${lib.optionalString idleLock ''
            [idle.behavior.lock]
            enabled = true
            timeout = 300
          ''}'
      '';

      # Without --skip-ddc-checks, every ddcutil invocation re-runs a full display
      # detect, which dominates a brightness change: 0.50s vs 0.05s on the U3223QE.
      # noctalia builds its ddcutil argv in C++, so the flag is injected via PATH.
      fast-ddcutil = self.lib.wrapPackage pkgs {
        package = pkgs.ddcutil;
        flags = [ "--skip-ddc-checks" ];

        # ddcutil shells out to uname; wrapPackage otherwise leaves it an empty PATH.
        runtimeInputs = [ pkgs.coreutils ];
      };
    in
    self.lib.wrapPackage pkgs {
      package = pkgs.noctalia;

      env.NOCTALIA_CONFIG_HOME = configHome;

      # The launcher resolves desktop-entry Exec= against noctalia's own PATH.
      inheritPath = true;

      runtimeInputs = [
        fast-ddcutil
        pkgs.bitwarden-cli
      ];

      checks = [ "${pkgs.noctalia}/bin/noctalia config validate ${configHome}/noctalia" ];
    };
in
{
  perSystem =
    { pkgs, lib, ... }:
    {
      packages = self.lib.onlySupported {
        noctalia-wrapped = makeNoctalia {
          inherit pkgs lib;
          vramWidget = true;
          idleLock = true;
        };
      };
    };

  # The desktop shell: bar, launcher, notification centre and lock screen in one.
  flake.nixosModules.noctalia =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      options.wrappers.noctalia.idleLock = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Whether the shell locks the session after five minutes idle. tower
          sets this false: it never leaves the flat, and its seat is the console
          for the services it runs.
        '';
      };

      config.programs.noctalia = {
        enable = true;
        systemd.enable = true;

        # The module's default package is v5, a native binary with niri support
        # compiled in (compositors::niri::NiriRuntime, driven off NIRI_SOCKET).
        package = makeNoctalia {
          inherit pkgs lib;
          vramWidget = config.gpu.hasVramStat;
          idleLock = config.wrappers.noctalia.idleLock;
        };

        recommendedServices.enable = true;
      };
    };
}
