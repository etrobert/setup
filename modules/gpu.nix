_: {
  # Hardware traits a host states about its own GPU. Consumers derive package
  # choices from these, so a host says what is true of it rather than naming
  # the build that follows.
  flake.nixosModules.gpu =
    { lib, ... }:
    {
      options.gpu = {
        hasAv1Decode = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = ''
            Whether the GPU decodes AV1 in hardware. When false, browsers are
            built with AV1 disabled, so sites serve VP9 rather than pinning the
            CPU on software decode.
          '';
        };

        hasVramStat = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = ''
            Whether the GPU exposes a VRAM usage statistic. When false, the
            shell drops its VRAM widget, which would otherwise render
            permanently empty — noctalia has no hide-when-unavailable option.
          '';
        };
      };
    };
}
