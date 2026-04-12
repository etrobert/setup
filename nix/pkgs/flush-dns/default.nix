{ writeShellApplication }:
writeShellApplication {
  name = "flush-dns";
  inheritPath = false;
  text = ''
    sudo dscacheutil -flushcache
    sudo killall -HUP mDNSResponder
  '';
}
