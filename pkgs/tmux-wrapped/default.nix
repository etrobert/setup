{
  tmux,
  wrapPackage,
}:
wrapPackage {
  package = tmux;
  flags = [ "-f ${./tmux.conf}" ];
}
