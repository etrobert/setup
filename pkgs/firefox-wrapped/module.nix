# What firefox-wrapped is, stated once and independently of any `pkgs`.
# `pkgs` arrives as a specialArg, so the same module builds the flake's package
# outputs and a host's own instance.
{
  config,
  lib,
  pkgs,
  self,
  ...
}:
let
  browserConfig = import (self + /lib/browser-config.nix) { inherit lib; };
in
{
  options = {
    # Hardware AV1 decode is broken on the i915 iGPU; software decode of the
    # same streams pins the CPU, so turn AV1 off there instead.
    av1 = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };

    wrapper = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
    };
  };

  config.wrapper = pkgs.wrapFirefox pkgs.firefox-unwrapped {
    extraPrefs = browserConfig.renderDefaultPrefs (
      browserConfig.sharedSettings // lib.optionalAttrs (!config.av1) { "media.av1.enabled" = false; }
    );
    extraPolicies = browserConfig.sharedPolicies;
  };
}
