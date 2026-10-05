_: {
  flake.nixosModules.cursor =
    { pkgs, lib, ... }:
    let
      # Must match the cursor block in niri-wrapped/config.kdl
      theme = "Bibata-Modern-Classic";
      size = 30;
    in
    {
      environment.systemPackages = [
        pkgs.bibata-cursors
        # ankama-launcher (sandboxed Electron on X11) can't read the dconf cursor-theme and falls back to "default"
        (pkgs.writeTextDir "share/icons/default/index.theme" /* ini */ ''
          [Icon Theme]
          Inherits=${theme}
        '')
      ];

      # ankama-launcher (Electron on X11) ignores the dconf cursor-size and otherwise guesses it from DPI
      environment.sessionVariables.XCURSOR_SIZE = toString size;

      # GTK apps ignore niri's cursor config and read the theme from GSettings
      programs.dconf = {
        enable = true;
        profiles.user.databases = [
          {
            settings."org/gnome/desktop/interface" = {
              cursor-theme = theme;
              cursor-size = lib.gvariant.mkInt32 size;
            };
          }
        ];
      };
    };
}
