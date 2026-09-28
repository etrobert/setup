---
paths:
  - "**/*.nix"
---

# Nix Style

Avoid overlays. Expose packages and modules as flake outputs with flake-parts,
and reference them through `self.` (e.g. `self.nixosModules.foo`) or `self'.`
(e.g. `self'.packages.foo`).

When embedding another language inside a plain Nix string, add a language hint
comment so that treesitter understands it.
