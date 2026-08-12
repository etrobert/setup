# Web chat frontend for the local ollama instance (features/ollama.nix), joined
# to the tailnet as `chat/` by features/tailnet-services.nix. It listens on
# localhost only — tsnsrv is the sole way in.
_: {
  flake.nixosModules.openWebui =
    { config, ... }:
    {
      # nixpkgs marks Open WebUI non-free over its MIT -> modified-BSD-3
      # relicensing and the branding clause that came with it. Personal use is
      # unaffected by that clause.
      allowedUnfreePackages = [ "open-webui" ];

      services.open-webui = {
        enable = true;

        # Not the module's default 8080: rift-radar's backend already holds it.
        port = 8090;

        # Defining `environment` at all replaces the module's default, so the
        # telemetry opt-outs have to be repeated here.
        environment = {
          OLLAMA_BASE_URL = "http://127.0.0.1:${toString config.services.ollama.port}";

          # Links Open WebUI generates for itself (shares, notifications) — the
          # module would otherwise point them at its own localhost port.
          WEBUI_URL = "http://chat";

          SCARF_NO_ANALYTICS = "True";
          DO_NOT_TRACK = "True";
          ANONYMIZED_TELEMETRY = "False";
        };
      };
    };
}
