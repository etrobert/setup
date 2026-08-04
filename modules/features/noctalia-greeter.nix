{ inputs, ... }:
{
  # The login screen, in the shell's visual language. Enables greetd and points
  # its session at the greeter's own wlroots compositor.
  flake.nixosModules.noctaliaGreeter.imports = [
    inputs.noctalia-greeter.nixosModules.default

    (
      { lib, pkgs, ... }:
      let
        # The shell downloads this palette from api.noctalia.dev at run time;
        # the greeter reads the same colours from the pinned repo behind that
        # API. The two spell their roles differently — mOnSurfaceVariant
        # against on_surface_variant — and "terminal" holds ANSI colours, not
        # a role.
        palette =
          let
            name = (lib.importTOML ../../pkgs/noctalia-wrapped/config.toml).theme.community_palette;

            upper = lib.stringToCharacters "ABCDEFGHIJKLMNOPQRSTUVWXYZ";

            toRole =
              role:
              lib.removePrefix "_" (lib.toLower (builtins.replaceStrings upper (map (c: "_${c}") upper) role));
          in
          lib.mapAttrs' (role: lib.nameValuePair (toRole (lib.removePrefix "m" role))) (
            lib.filterAttrs (
              role: _: role != "terminal"
            ) (lib.importJSON "${inputs.noctalia-community-palettes}/${name}/${name}.json").dark
          );
      in
      {
        programs.noctalia-greeter = {
          enable = true;

          settings = {
            # A complete palette here outranks whatever Sync Now last wrote, so
            # the login screen is reproducible rather than a leftover of the
            # last time someone pressed the button. It also carries the
            # wallpaper: a builtin scheme calls clearWallpaperDisplay(), so
            # trading this for scheme = "Catppuccin" loses the wallpaper too.
            appearance = {
              scheme = "Synced";
              inherit palette;

              wallpaper.path = "${../../assets/saint-levant.jpg}";
            };

            cursor = {
              theme = "Bibata-Modern-Classic";
              size = 30;
              path = "${pkgs.bibata-cursors}/share/icons";
            };
          };
        };
      }
    )
  ];
}
