# Helper that eliminates the repeated symlinkJoin + wrapProgram boilerplate
# across *-wrapped packages.  Pass it the package to wrap and declare what
# the wrapper should do; it produces a derivation whose outputs look like the
# original package with a wrapProgram-generated launcher in bin/.
#
# Usage:
#
#   wrapPackage {
#     package        = pkgs.foo;           # required – base package
#     binName        ? <mainProgram>;      # binary name; default: mainProgram or lib.getName
#     name           ? "${binName}-wrapped"; # derivation name
#     env            ? {};                 # --set NAME value  (attrset)
#     setDefaults    ? {};                 # --set-default NAME value  (attrset)
#     flags          ? [];                 # raw strings; each becomes one --add-flags "…"
#     runtimeInputs  ? [];                 # packages; becomes --prefix PATH : (makeBinPath …)
#     extraWrapArgs  ? [];                 # raw shell words appended verbatim to wrapProgram
#     extraPaths     ? [];                 # extra symlinkJoin paths (e.g. check derivations)
#     filesToPatch   ? [];                 # shell globs; matching service/dbus files are
#                                         #   rewritten to reference $out instead of the
#                                         #   original package store path
#     passthru       ? {};                 # forwarded to the symlinkJoin result
#     postBuild      ? "";                 # shell fragment run after wrapProgram (escape hatch)
#   }
#
# filesToPatch loop is modelled on Lassulus/wrappers (MIT): for each glob match,
# resolve the symlink to its target, grep for the original store path, copy the
# file (replacing the symlink) and substituteInPlace it to point at $out.
# When a glob matches nothing the loop is a no-op (guarded with nullglob).
{
  lib,
  symlinkJoin,
  makeWrapper,
}:

{
  package,
  binName ? package.meta.mainProgram or (lib.getName package),
  name ? "${binName}-wrapped",
  env ? { },
  setDefaults ? { },
  flags ? [ ],
  runtimeInputs ? [ ],
  extraWrapArgs ? [ ],
  extraPaths ? [ ],
  filesToPatch ? [ ],
  passthru ? { },
  postBuild ? "",
}:
let
  # Build the wrapProgram argument lines.  Each element of `lines` is one
  # continuation line (the line-continuation backslash is added by the join).
  lines =
    lib.mapAttrsToList (k: v: "    --set ${lib.escapeShellArg k} ${lib.escapeShellArg v}") env
    ++ lib.mapAttrsToList (
      k: v: "    --set-default ${lib.escapeShellArg k} ${lib.escapeShellArg v}"
    ) setDefaults
    # --add-flags values are inserted *verbatim* into the generated wrapper
    # script (see makeWrapper docs: "ARGS verbatim to the Bash-interpreted
    # invocation").  Double-quoting keeps the value as one shell word during
    # the wrapProgram call; bash processes any quoting inside the value when
    # the wrapper actually runs.
    ++ map (f: "    " + ''--add-flags "${f}"'') flags
    ++ lib.optional (runtimeInputs != [ ]) "    --prefix PATH : ${lib.makeBinPath runtimeInputs}"
    ++ lib.optional (extraWrapArgs != [ ]) (
      "    " + lib.concatStringsSep " " (map lib.escapeShellArg extraWrapArgs)
    );

  wrapCall =
    "wrapProgram $out/bin/${binName}"
    + (if lines == [ ] then "" else " \\\n" + lib.concatStringsSep " \\\n" lines);

  # filesToPatch: for each glob, iterate matches, resolve the symlink, check
  # whether the file references the original package store path, then copy it
  # (replacing the symlink with a writable file) and substitute in-place.
  # Modelled on Lassulus/wrappers (MIT).  nullglob makes missing globs a no-op.
  patchScript = lib.optionalString (filesToPatch != [ ]) (
    ''
      shopt -s nullglob
    ''
    + lib.concatMapStringsSep "\n" (glob: ''
      for _wrap_pkg_f in ${glob}; do
        _wrap_pkg_target=$(readlink -f "$_wrap_pkg_f")
        if grep -qF ${lib.escapeShellArg "${package}"} "$_wrap_pkg_target" 2>/dev/null; then
          rm "$_wrap_pkg_f"
          cp --no-preserve=mode "$_wrap_pkg_target" "$_wrap_pkg_f"
          substituteInPlace "$_wrap_pkg_f" \
            --replace-fail ${lib.escapeShellArg "${package}"} "$out"
        fi
      done
    '') filesToPatch
    + ''
      shopt -u nullglob
    ''
  );
in
symlinkJoin {
  inherit name passthru;
  nativeBuildInputs = [ makeWrapper ];
  paths = [ package ] ++ extraPaths;
  meta.mainProgram = binName;
  postBuild = ''
    ${wrapCall}

    ${patchScript}${postBuild}
  '';
}
