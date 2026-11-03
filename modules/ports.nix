_: {
  flake.nixosModules.ports =
    { config, lib, ... }:
    let
      hashPort =
        name:
        20000
        + lib.mod (lib.fromHexString (builtins.substring 0 8 (builtins.hashString "sha256" name))) 10000;
    in
    {
      options.ports = lib.mkOption {
        type = lib.types.attrsOf (lib.types.either lib.types.port (lib.types.enum [ "auto" ]));
        default = { };
        description = ''
          The port each service on this host listens on, read back as
          `config.ports.<name>`. `"auto"` hashes the name into 20000-29999, so
          the port never moves as other services come and go: use it only where
          everything that reaches the port reads it from this host's config.
        '';
        apply = lib.mapAttrs (name: port: if port == "auto" then hashPort name else port);
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
