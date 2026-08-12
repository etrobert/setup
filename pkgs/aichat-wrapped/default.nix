{
  aichat-shim,
  aichat,
  coreutils,
  lib,
  writeShellApplication,
}:
# A script rather than a wrapper: the shim has to be stopped once aichat exits,
# and `trap … EXIT` is the plainest way to say that. It also rules out `exec`,
# which would replace the shell that owes us the trap.
writeShellApplication {
  name = "aichat";
  runtimeInputs = [ coreutils ];
  # Unlike most scripts here: aichat runs the accepted command by spawning
  # `$SHELL -c`, so it needs the caller's PATH rather than a pinned one.
  inheritPath = true;
  text = ''
    # One shim per aichat, started here so claude inherits the caller's
    # directory and reads that project's CLAUDE.md.
    dir=$(mktemp --directory)
    ${lib.getExe aichat-shim} --config "$dir/config.yaml" &
    shim=$!
    trap 'kill "$shim" 2>/dev/null || true; rm --recursive --force "$dir"' EXIT INT TERM HUP

    # The shim binds a free port, then writes the config naming it. It is
    # already listening by the time the file appears.
    until [ -e "$dir/config.yaml" ]; do sleep 0.02; done

    AICHAT_CONFIG_FILE="$dir/config.yaml" ${lib.getExe aichat} "$@"
  '';
}
