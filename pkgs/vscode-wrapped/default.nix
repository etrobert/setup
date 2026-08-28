_: {
  perSystem =
    { pkgs, ... }:
    {
      packages.vscode-wrapped = pkgs.callPackage ./package.nix { };
    };
}
