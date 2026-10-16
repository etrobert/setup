{ self, inputs, ... }:
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

      # The release tarball, unpacked. The flake input tracks Zen's latest
      # release, so `nix flake update` is the whole update path.
      src = inputs.zen-browser;

      # The tarball carries its own version metadata: Zen's in application.ini,
      # the Firefox it is built on in platform.ini.
      iniValue =
        file: key:
        lib.removePrefix "${key}=" (
          lib.findFirst (lib.hasPrefix "${key}=") (throw "zen-browser: no ${key}= in ${file}") (
            lib.splitString "\n" (builtins.readFile "${src}/${file}")
          )
        );
      version = iniValue "application.ini" "Version";
      firefoxVersion = iniValue "platform.ini" "Milestone";

      # Modeled on nixpkgs' firefox-bin-unwrapped, whose passthru is the
      # contract wrapFirefox reads.
      zen-browser-unwrapped = pkgs.stdenv.mkDerivation {
        pname = "zen-browser-unwrapped";
        inherit version src;

        nativeBuildInputs = with pkgs; [
          wrapGAppsHook3
          autoPatchelfHook
          patchelfUnstable # for --no-clobber-old-sections
        ];
        buildInputs = with pkgs; [
          gtk3
          adwaita-icon-theme
          alsa-lib
          dbus-glib
          libxtst
        ];
        runtimeDependencies = with pkgs; [
          curl
          pciutils
          libva.out
        ];
        appendRunpaths = [ "${pkgs.pipewire}/lib" ];
        # Firefox uses "relrhack" to manually process relocations from a fixed offset
        patchelfFlags = [ "--no-clobber-old-sections" ];

        installPhase = ''
          mkdir -p "$out/lib/zen-${version}"
          cp -r * "$out/lib/zen-${version}"

          mkdir -p "$out/bin"
          ln -s "$out/lib/zen-${version}/zen" "$out/bin/zen"
        '';

        passthru = {
          applicationName = "Zen Browser";
          binaryName = "zen";
          libName = "zen-${version}";
          withFFmpeg = true;
          withGSSAPI = true;
          inherit (pkgs) gtk3;
        };

        meta = {
          description = "Firefox-based browser (upstream binary release)";
          homepage = "https://zen-browser.app";
          license = lib.licenses.mpl20;
          sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
          platforms = [ "x86_64-linux" ];
          mainProgram = "zen";
        };
      };

      makeZen =
        extraSettings:
        # wrapFirefox picks the FFmpeg ABI from browser.version, which must be
        # the Firefox version, not Zen's own.
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
      # The zen-browser input is the x86_64-linux tarball.
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

      # The input's URL is a moving `latest`, so once Zen releases again the
      # locked tarball can only come from a store. Rooting it here keeps it
      # through GC, and harmonia then serves it to any host evaluating a lock
      # that no longer matches the URL.
      system.extraDependencies = [ inputs.zen-browser ];
    };
}
