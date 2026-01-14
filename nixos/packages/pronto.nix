{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:

rustPlatform.buildRustPackage rec {
  pname = "pronto";
  version = "unstable-2025-01-01";

  src = fetchFromGitHub {
    owner = "etrobert";
    repo = "pronto";
    rev = "main";
    sha256 = "0194mjr907jbvpc87m4j7wkyzanjvi2v9fp2znhzdd65v6nk29dq";
  };

  cargoLock = {
    lockFile = src + "/Cargo.lock";
  };

  meta = with lib; {
    description = "Rust-based shell prompt/status tool";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
