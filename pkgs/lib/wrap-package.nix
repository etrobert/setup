# Helper that eliminates the repeated symlinkJoin + wrapProgram boilerplate
# across *-wrapped packages.  Pass it the package to wrap and declare what
# the wrapper should do; it produces a derivation whose outputs look like the
# original package with a wrapProgram-generated launcher in bin/.
#
# Usage:
#
#   wrapPackage {
#     package        = pkgs.foo;           # required – base package
#     binName        ? <mainProgram>;      # binary name; default: package.meta.mainProgram
#     name           ? "${binName}-wrapped"; # derivation name
#     flags          ? [];                 # raw strings; each becomes one --add-flags "…"
#     runtimeInputs  ? [];                 # packages; becomes --prefix PATH : (makeBinPath …)
#     filesToPatch   ? [];                 # explicit file paths (may contain $out);
#                                         #   each service/dbus file is rewritten to
#                                         #   reference $out instead of the original
#                                         #   package store path
#   }
#
# This is the minimal surface needed by the waybar pilot; later conversions add
# more options (env, setDefaults, …) as they need them.
#
# filesToPatch: for each listed file, resolve the symlink to its target, copy
# the file (replacing the symlink with a writable copy) and substituteInPlace it
# to point at $out.  Assertive: a missing file or an absent package path is a
# build error, so a stale entry never goes unnoticed.
{
  lib,
  symlinkJoin,
  makeWrapper,
}:

{
  package,
  binName ? package.meta.mainProgram,
  name ? "${binName}-wrapped",
  flags ? [ ],
  runtimeInputs ? [ ],
  filesToPatch ? [ ],
}:
let
  # Build the wrapProgram argument lines.  Each element of `lines` is one
  # continuation line (the line-continuation backslash is added by the join).
  lines =
    # --add-flags values are inserted *verbatim* into the generated wrapper
    # script (see makeWrapper docs: "ARGS verbatim to the Bash-interpreted
    # invocation").  Double-quoting keeps the value as one shell word during
    # the wrapProgram call; bash processes any quoting inside the value when
    # the wrapper actually runs.
    map (f: "    " + ''--add-flags "${f}"'') flags
    # --set (not --prefix): replace PATH with exactly runtimeInputs, so the
    # wrapped program runs against a known set of tools regardless of the PATH
    # it was launched with.  (Note this differs from writeShellApplication's
    # runtimeInputs, which *prepends*.)
    ++ lib.optional (runtimeInputs != [ ]) "    --set PATH ${lib.makeBinPath runtimeInputs}";

  wrapCall =
    "wrapProgram $out/bin/${binName}"
    + (if lines == [ ] then "" else " \\\n" + lib.concatStringsSep " \\\n" lines);

  # filesToPatch: rewrite each listed file's reference to the original package
  # store path so it points at $out instead.  The files are symlinks (from
  # symlinkJoin), so resolve the target, replace the symlink with a writable
  # copy (store files are read-only — --no-preserve=mode makes the copy
  # writable so substituteInPlace can edit it), then substitute.  Assertive:
  # the build runs under `set -e`, so rm fails it if a listed file is missing,
  # and --replace-fail errors if the package path isn't present — a stale entry
  # never passes silently.
  patchScript = lib.concatMapStringsSep "\n" (file: ''
    _wrap_pkg_target=$(readlink -f "${file}")
    rm "${file}"
    cp --no-preserve=mode "$_wrap_pkg_target" "${file}"
    substituteInPlace "${file}" \
      --replace-fail ${lib.escapeShellArg "${package}"} "$out"
  '') filesToPatch;
in
symlinkJoin {
  inherit name;
  nativeBuildInputs = [ makeWrapper ];
  paths = [ package ];
  meta.mainProgram = binName;
  postBuild = ''
    ${wrapCall}

    ${patchScript}
  '';
}
