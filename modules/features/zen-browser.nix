{ self, ... }:
{
  perSystem =
    {
      pkgs,
      lib,
      system,
      ...
    }:
    let
      inherit (self.lib) browserConfig;

      # Bumped by the update-zen workflow
      inherit (lib.importJSON ./zen-browser.json) version firefoxVersion hash;

      # Based on nixpkgs' firefox-bin-unwrapped
      # wrapFirefox reads its passthru
      zen-browser-unwrapped = pkgs.stdenv.mkDerivation {
        pname = "zen-browser-unwrapped";
        inherit version;
        src = pkgs.fetchzip {
          url = "https://github.com/zen-browser/desktop/releases/download/${version}/zen.linux-x86_64.tar.xz";
          inherit hash;
        };

        nativeBuildInputs = with pkgs; [
          wrapGAppsHook3
          autoPatchelfHook
          patchelfUnstable # stable patchelf 0.15 lacks --no-clobber-old-sections
        ];
        buildInputs = with pkgs; [
          gtk3
          alsa-lib
        ];
        # Firefox uses "relrhack" to manually process relocations from a fixed offset
        patchelfFlags = [ "--no-clobber-old-sections" ];

        installPhase = ''
          mkdir -p "$out/lib/zen" "$out/bin"
          cp -r * "$out/lib/zen"
          ln -s "$out/lib/zen/zen" "$out/bin/zen"
        '';

        passthru = {
          applicationName = "Zen Browser";
          binaryName = "zen";
          withFFmpeg = true;
          withPipewire = true;
          inherit (pkgs) gtk3;
        };
      };

      makeZen =
        extraSettings:
        # wrapFirefox picks the FFmpeg ABI from browser.version, so it needs Firefox's, not Zen's
        pkgs.wrapFirefox (zen-browser-unwrapped // { version = firefoxVersion; }) {
          inherit version;
          extraPrefs = browserConfig.renderDefaultPrefs (
            browserConfig.sharedSettings
            // {
              "zen.theme.content-element-separation" = 4;
              "zen.theme.border-radius" = 12;
              # Zen's own Sync engine for the sidebar (spaces, folders, pinned
              # tabs, essentials). Ships disabled; unpinned tabs stay local.
              "services.sync.engine.spaces" = true;
            }
            // extraSettings
          );
          extraPolicies = browserConfig.sharedPolicies;
        };
    in
    {
      packages = lib.optionalAttrs (system == "x86_64-linux") {
        zen-browser-wrapped = makeZen { };

        # Hardware AV1 decode is broken on the i915 iGPU; software decode of the
        # same streams pins the CPU, so turn AV1 off there instead.
        zen-browser-wrapped-no-av1 = makeZen { "media.av1.enabled" = false; };
      };
    };

  flake.nixosModules.zen-browser =
    { config, pkgs, ... }:
    let
      inherit (pkgs.stdenv.hostPlatform) system;
      inherit (self.packages.${system}) zen-browser-wrapped zen-browser-wrapped-no-av1;
    in
    {
      environment.systemPackages = [
        (if config.gpu.hasAv1Decode then zen-browser-wrapped else zen-browser-wrapped-no-av1)
      ];
    };
}
