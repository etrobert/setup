# Wraps the ntfy CLI with NTFY_TOPIC pre-set to our self-hosted endpoint so
# `ntfy publish "msg"` reaches it without naming the server or topic.
# Endpoint mirrors host/port/topic in modules/ntfy.nix.
{
  lib,
  makeWrapper,
  ntfy-sh,
  runCommandLocal,
}:
runCommandLocal "ntfy-wrapped"
  {
    nativeBuildInputs = [ makeWrapper ];
    meta.mainProgram = "ntfy";
  }
  ''
    makeWrapper ${lib.getExe ntfy-sh} $out/bin/ntfy \
      --set-default NTFY_TOPIC http://tower:2586/home
  ''
