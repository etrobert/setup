{
  lib,
  stdenvNoCC,
  fetchurl,
  undmg,
  version,
}:

# Upstream's Nix flake is Linux-only, so darwin unpacks the official DMG at the
# version that flake pins. The bundle stays untouched: it is Developer ID
# signed with restricted entitlements, so wrapFirefox's rewrites (as used on
# Linux) break the seal and macOS kills the app. Prefs and policies arrive
# through the app's preferences domain instead — see modules/hosts/aaron.
stdenvNoCC.mkDerivation {
  pname = "zen-browser";
  inherit version;

  # Bump alongside the zen-browser flake input, which supplies `version`: a
  # stale hash here fails the fetch.
  src = fetchurl {
    url = "https://github.com/zen-browser/desktop/releases/download/${version}/zen.macos-universal.dmg";
    hash = "sha256-bufrCa4/ku9W0UNArMeUi0XXaAbSMqVN4jqM00g2Gwk=";
  };

  sourceRoot = ".";

  nativeBuildInputs = [ undmg ];

  # Keeps the vendor signature intact.
  dontFixup = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/Applications
    mv Zen.app $out/Applications/Zen.app

    runHook postInstall
  '';

  meta = {
    description = "Privacy-focused Firefox fork (macOS binary release)";
    homepage = "https://zen-browser.app";
    license = lib.licenses.mpl20;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = lib.platforms.darwin;
    mainProgram = "zen";
  };
}
