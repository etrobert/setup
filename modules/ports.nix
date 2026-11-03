_: {
  flake.nixosModules.ports =
    { config, lib, ... }:
    let
      autoBase = 20000;
    in
    {
      options.ports = lib.mkOption {
        type = lib.types.attrsOf (lib.types.either lib.types.port (lib.types.enum [ "auto" ]));
        default = { };
        description = ''
          The port each service on this host listens on, read back as
          `config.ports.<name>`. `"auto"` services are numbered from
          ${toString autoBase} in name order, so adding a service can move
          those after it: use it only where everything that reaches the port
          reads it from this host's config. Fixed ports belong below
          ${toString autoBase}.
        '';
        apply =
          requests:
          let
            auto = lib.attrNames (lib.filterAttrs (_: port: port == "auto") requests);
          in
          removeAttrs requests auto
          // lib.listToAttrs (lib.imap0 (i: name: lib.nameValuePair name (autoBase + i)) auto);
      };

      config.assertions =
        let
          ports = lib.attrValues config.ports;
          isShared = port: lib.count (other: other == port) ports > 1;
          shared = lib.filterAttrs (_: isShared) config.ports;
        in
        [
          {
            assertion = shared == { };
            message = "These services share a port: ${lib.generators.toPretty { } shared}";
          }
        ];
    };
}
