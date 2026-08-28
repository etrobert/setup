{ callPackage, inputs, ... }:
{
  noctalia-wrapped = callPackage ./default.nix {
    official-plugins = inputs.noctalia-official-plugins;
    community-plugins = inputs.noctalia-community-plugins;
  };
}
