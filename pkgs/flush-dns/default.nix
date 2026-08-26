{ writeShellApplication }:
writeShellApplication {
  name = "flush-dns";
  inheritPath = true;
  text = /* bash */ ''
    sudo dscacheutil -flushcache
    sudo killall -HUP mDNSResponder
  '';
}
