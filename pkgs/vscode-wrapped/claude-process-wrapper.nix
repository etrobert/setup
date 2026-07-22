{ self', writeShellApplication }:

# The Claude Code VS Code extension launches its own bundled CLI by default,
# bypassing claude-code-wrapped entirely. claudeCode.claudeProcessWrapper (set
# in user-data/User/settings.json) makes the extension invoke this shim as
# `wrapper <bundled-cli> <args…>`; it drops the bundled CLI and runs
# claude-code-wrapped instead.
writeShellApplication {
  name = "claude-process-wrapper";

  runtimeInputs = [ self'.packages.claude-code-wrapped ];

  # Keep the caller's PATH (the extension resolves the user's shell PATH for
  # the Claude process, which needs it to run project tools).
  inheritPath = true;

  text = ''
    shift
    exec claude "$@"
  '';
}
