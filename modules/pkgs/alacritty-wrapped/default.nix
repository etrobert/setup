_: {
  perSystem =
    { pkgs, self', ... }:
    {
      packages.alacritty-wrapped =
        let
          configFile = pkgs.writeText "alacritty.toml" /* toml */ ''
            [env]
            TERM = "xterm-256color"

            [window]
            padding.x = 10
            padding.y = 10

            decorations = "Buttonless"

            option_as_alt = "Both"

            [font]
            normal.family = "FiraCode Nerd Font"
            size = 13

            [general]
            import = [ "${./catppuccin-macchiato.toml}" ]
          '';
        in
        self'.legacyPackages.wrapPackage {
          package = pkgs.alacritty;
          flags = [ "--config-file ${configFile}" ];
          inheritPath = true;
        };
    };
}
