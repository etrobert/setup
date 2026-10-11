{ inputs, ... }:
{
  perSystem =
    { pkgs, self', ... }:
    let
      # Local providers replace the default GitHub clones, so a sync runs offline and moves with flake.lock.
      settings = (pkgs.formats.yaml { }).generate "settings.yml" {
        resource_providers = [
          {
            name = "trash-guides";
            type = "trash-guides";
            path = "${inputs.trash-guides}";
            replace_default = true;
          }
          # The configs use no config templates or includes.
          {
            name = "config-templates";
            type = "config-templates";
            path = "${pkgs.emptyDirectory}";
            replace_default = true;
          }
        ];
      };
    in
    {
      packages.recyclarr-wrapped = self'.legacyPackages.wrapPackage {
        package = pkgs.recyclarr;
        # Recyclarr reads settings.yml only from its config dir, which also holds its state.
        run = [
          ''${pkgs.coreutils}/bin/ln --symbolic --force ${settings} "$RECYCLARR_CONFIG_DIR/settings.yml"''
        ];
      };
    };
}
