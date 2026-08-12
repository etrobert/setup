{
  callPackage,
  claude-code-wrapped,
  aichat,
  coreutils,
  lib,
  writeShellApplication,
}:
let
  # Only ever started by the script below, so it stays an implementation
  # detail here rather than a package of its own.
  aichat-shim = callPackage ./shim.nix { inherit claude-code-wrapped; };
in
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
    # Cleanup first: Ctrl-C reaches the shim too, so by the time the trap runs
    # the kill often has nothing left to kill.
    trap 'rm --recursive --force "$dir"; kill "$shim"' EXIT INT TERM HUP

    # The shim binds a free port, then writes the config naming it. It is
    # already listening by the time the file appears.
    until [ -e "$dir/config.yaml" ]; do sleep 0.02; done

    AICHAT_CONFIG_FILE="$dir/config.yaml" ${lib.getExe aichat} "$@"
  '';
}
