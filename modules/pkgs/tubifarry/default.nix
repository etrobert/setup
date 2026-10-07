_: {
  perSystem =
    { pkgs, ... }:
    {
      packages.tubifarry = pkgs.fetchzip {
        pname = "tubifarry";
        version = "2.2.0.5";
        url = "https://github.com/TypNull/Tubifarry/releases/download/v2.2.0.5/Tubifarry-v2.2.0.5.net8.0.zip";
        stripRoot = false;
        hash = "sha256-/ps/hQl1qsSFMFroyD9/ZKnp7/7yMhBgUXxmAhmoNFc=";
      };
    };
}
