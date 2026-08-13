# Caps Lock as tap-Escape / hold-Control, and Escape as tap-Escape / hold-CapsLock.
_: {
  flake.nixosModules.kanata = _: {
    services.kanata = {
      enable = true;
      keyboards.default = {
        config = /* scheme */ ''
          (defsrc
            caps
            esc
          )

          (deflayer base
            (tap-hold-press 0 200 esc lctl)
            (tap-hold 200 200 esc caps)
          )
        '';
        extraDefCfg = "process-unmapped-keys yes";
      };
    };
  };
}
