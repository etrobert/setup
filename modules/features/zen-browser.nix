{ self, ... }:
{
  perSystem =
    {
      pkgs,
      lib,
      inputs',
      ...
    }:
    let
      inherit (self.lib) browserConfig;

      # nixpkgs renamed the wrapper's passthru flags (ffmpegSupport → withFFmpeg,
      # gssSupport → withGSSAPI); the zen flake still sets the old names, so
      # wrapFirefox leaves libavcodec off LD_LIBRARY_PATH and H.264/AAC are gone.
      # Drop once youwen5/zen-browser-flake#19 is fixed; the assertion fires then.
      zen-browser-unwrapped =
        let
          upstream = inputs'.zen-browser.packages.zen-browser-unwrapped;
        in
        assert lib.assertMsg (!(upstream.passthru ? withFFmpeg))
          "zen-browser-flake now sets withFFmpeg itself — drop the override in modules/features/zen-browser.nix";
        upstream.overrideAttrs (old: {
          passthru = old.passthru // {
            withFFmpeg = true;
            withGSSAPI = true;
          };
        });

      makeZen =
        extraSettings:
        pkgs.wrapFirefox zen-browser-unwrapped {
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
      # The zen-browser input has no darwin outputs, so this cannot be built there.
      packages = lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
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
