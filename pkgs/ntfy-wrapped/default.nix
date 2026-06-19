# Wraps the ntfy CLI with NTFY_TOPIC pre-set to our self-hosted endpoint so
# `ntfy publish "msg"` reaches it without naming the server or topic.
# Endpoint mirrors host/port/topic in modules/ntfy.nix.
{
  ntfy-sh,
  wrapPackage,
}:
wrapPackage {
  package = ntfy-sh;
  # Allow per-invocation overrides via the environment.
  setDefaults.NTFY_TOPIC = "http://tower:2586/home";
}
