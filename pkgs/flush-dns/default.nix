_: {
  perSystem =
    { pkgs, lib, ... }:
    {
      packages = lib.filterAttrs (_: p: !p.meta.unsupported) {
        flush-dns = pkgs.writeShellApplication {
          name = "flush-dns";
          meta.platforms = lib.platforms.darwin;
          inheritPath = true;
          text = ''
            sudo dscacheutil -flushcache
            sudo killall -HUP mDNSResponder
          '';
        };
      };
    };
}
