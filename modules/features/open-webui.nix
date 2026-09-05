# Web chat frontend for the local ollama instance (features/ollama.nix), joined
# to the tailnet as `chat/` through tsnsrv. It listens on localhost only —
# tsnsrv is the sole way in.
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

        # Not the module's default 8080: the lafraise dev backend binds it.
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

      services.tsnsrv.services.chat = {
        toURL = "http://127.0.0.1:${toString config.services.open-webui.port}";
        plaintext = true;

        # Open WebUI's websocket upgrade fails on any non-ASCII header value:
        # websockets >= 16.1 decodes header values as ISO-8859-1, and uvicorn's
        # sansio websocket path then re-encodes them as ASCII. The whois headers
        # carry the tailnet display name ("Étienne Robert"), which trips it.
        # Open WebUI authenticates its own users and ignores these headers
        # anyway.
        #
        # Passed via extraArgs because the tsnsrv NixOS module declares a
        # `suppressWhois` option but never renders it into the command line.
        extraArgs = [ "-suppressWhois=true" ];
      };
    };
}
