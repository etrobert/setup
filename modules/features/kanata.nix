# Caps Lock as Control.
_: {
  flake.nixosModules.kanata = _: {
    services.kanata = {
      enable = true;
      keyboards.default = {
        config = /* scheme */ ''
          (defsrc
            caps
          )

          (deflayer base
            lctl
          )
        '';
        extraDefCfg = "process-unmapped-keys yes";
      };
    };
  };
}
