{ lib }:
# A package whose meta says it does not run on the system being evaluated is
# dropped, rather than offered and failed on.
lib.filterAttrs (_: p: !p.meta.unsupported)
