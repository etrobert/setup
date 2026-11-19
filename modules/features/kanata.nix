# Caps Lock as Control, and Escape as tap-Escape / hold-CapsLock.
_: {
  flake.nixosModules.kanata =
    { config, lib, ... }:
    let
      keys = {
        caps = "lctl";
        esc = "(tap-hold 200 200 esc caps)";
      }
      // config.kanata.keys;
    in
    {
      options.kanata = {
        keys = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          default = { };
          description = "Extra source keys, each mapped to its Kanata action.";
        };
        extraConfig = lib.mkOption {
          type = lib.types.lines;
          default = "";
          description = "Extra top-level Kanata configuration.";
        };
      };

      config.services.kanata = {
        enable = true;
        keyboards.default = {
          config = /* scheme */ ''
            ${config.kanata.extraConfig}

            (defsrc
              ${lib.concatStringsSep "\n  " (lib.attrNames keys)}
            )

            (deflayer base
              ${lib.concatStringsSep "\n  " (lib.attrValues keys)}
            )
          '';
          extraDefCfg = "process-unmapped-keys yes";
        };
      };
    };
}
