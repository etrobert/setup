{ self, ... }:
{
  perSystem =
    {
      pkgs,
      lib,
      ...
    }:
    {
      packages = self.lib.onlySupported {
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
