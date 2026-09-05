# Flags declared flake modules that no host imports.
#
# Each host's `graph` is the tree of modules that took part in its evaluation,
# and flake-parts stamps every node a module contributes with
# "<flake source>/flake.nix#nixosModules.<name>". Collecting those stamps costs
# one evaluation per host and needs no subprocess, so this is a plain check
# rather than a script.
{ self, lib, ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      # unsafeDiscardStringContext: builtins.match refuses a pattern carrying
      # store-path context, which `self.outPath` does.
      stamp = ''${builtins.unsafeDiscardStringContext self.outPath}/flake\.nix#((nixos|darwin)Modules\..+)'';

      walk =
        node:
        [ (builtins.unsafeDiscardStringContext (toString node.file)) ]
        ++ lib.concatMap walk (node.imports or [ ]);

      modulesOf =
        config:
        lib.unique (
          map builtins.head (
            lib.filter (m: m != null) (
              map (builtins.match stamp) (lib.concatMap walk (lib.filter (n: !n.disabled) config.graph))
            )
          )
        );

      hosts = self.nixosConfigurations // self.darwinConfigurations;
      found = lib.mapAttrs (_: modulesOf) hosts;

      declared =
        map (n: "nixosModules.${n}") (lib.attrNames self.nixosModules)
        ++ map (n: "darwinModules.${n}") (lib.attrNames self.darwinModules);

      unused = lib.subtractLists (lib.unique (lib.concatLists (lib.attrValues found))) declared;
      # The stamp is a flake-parts convention. Were it to change, nothing would
      # match and every module would look unused, so a host that finds none is
      # a broken check rather than a finding.
      blind = lib.attrNames (lib.filterAttrs (_: ms: ms == [ ]) found);
    in
    {
      checks.dead-modules = pkgs.runCommand "dead-modules-check" { } (
        if blind != [ ] then
          ''
            echo "no modules matched for: ${lib.concatStringsSep " " blind}"
            echo "has the flake-parts provenance stamp changed?"
            exit 1
          ''
        else if unused != [ ] then
          ''
            echo "unused — no host imports these:"
            ${lib.concatMapStringsSep "\n" (m: ''echo "  ${m}"'') unused}
            exit 1
          ''
        else
          "touch $out"
      );
    };
}
