{ writeShellApplication }:
writeShellApplication {
  name = "flush-dns";
  inheritPath = true;
  text = ''
    sudo dscacheutil -flushcache
    sudo killall -HUP mDNSResponder
  '';
}
