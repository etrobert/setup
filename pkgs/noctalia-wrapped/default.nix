{ self, inputs, ... }:
{
  perSystem =
    {
      pkgs,
      lib,
      ...
    }:
    let
      official-plugins = inputs.noctalia-official-plugins;
      community-plugins = inputs.noctalia-community-plugins;

      makeNoctalia =
        withVramWidget:
        let
          plugins = ./plugins;

          wallpaper = ../../assets/saint-levant.jpg;

          configHome = pkgs.runCommand "noctalia-config-home" { } ''
            mkdir -p $out/noctalia
            substitute ${./config.toml} $out/noctalia/config.toml \
              --replace-fail '@plugins@' '${plugins}' \
              --replace-fail '@official-plugins@' '${official-plugins}' \
              --replace-fail '@community-plugins@' '${community-plugins}' \
              --replace-fail '@wallpaper@' '${wallpaper}' \
              --replace-fail '@vram-widget@' '${lib.optionalString withVramWidget ''"vram",''}'
          '';

          # Without --skip-ddc-checks, every ddcutil invocation re-runs a full display
          # detect, which dominates a brightness change: 0.50s vs 0.05s on the U3223QE.
          # noctalia builds its ddcutil argv in C++, so the flag is injected via PATH.
          fast-ddcutil = pkgs.wrapPackage {
            package = pkgs.ddcutil;
            flags = [ "--skip-ddc-checks" ];

            # ddcutil shells out to uname; wrapPackage otherwise leaves it an empty PATH.
            runtimeInputs = [ pkgs.coreutils ];
          };
        in
        pkgs.wrapPackage {
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
      packages = self.lib.onlySupported {
        noctalia-wrapped = makeNoctalia true;

        # Hosts whose GPU exposes no VRAM stat (e.g. an i915 iGPU) would render
        # the widget permanently empty; noctalia has no hide-when-unavailable option.
        noctalia-wrapped-no-vram = makeNoctalia false;
      };
    };

  flake.nixosModules.noctalia =
    { config, pkgs, ... }:
    let
      inherit (pkgs.stdenv.hostPlatform) system;
      inherit (self.packages.${system}) noctalia-wrapped noctalia-wrapped-no-vram;
    in
    {
      programs.noctalia.package =
        if config.gpu.hasVramStat then noctalia-wrapped else noctalia-wrapped-no-vram;
    };
}
