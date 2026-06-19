{
  vim,
  wrapPackage,
}:
wrapPackage {
  package = vim;
  flags = [
    "--cmd 'set rtp^=${./rtp}'"
    "-u ${./vimrc}"
  ];
}
