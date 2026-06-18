{
  writeShellApplication,
  timg,
  tmux,
}:
writeShellApplication {
  name = "ils";
  # tmux: inside tmux, timg shells out to `tmux set` to enable
  # allow-passthrough so the kitty graphics protocol reaches the outer
  # terminal. Without tmux on PATH it prints "Can't set passthrough".
  runtimeInputs = [
    timg
    tmux
  ];
  inheritPath = false;
  text = ''
    # Preview images in a grid in the terminal, with filenames as titles.
    # -pk forces the kitty graphics protocol so previews render inside tmux,
    # which otherwise suppresses graphics protocols (timg falls back to blocks).
    # Extra args are forwarded to timg, e.g. `ils --grid=4x4 foo/*.jpg`.
    exec timg -pk --grid=3x1 --title "$@"
  '';
}
