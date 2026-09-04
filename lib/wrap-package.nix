# Helper that eliminates the repeated symlinkJoin + wrapProgram boilerplate
# across *-wrapped packages.  Pass it the package to wrap and declare what
# the wrapper should do; it produces a derivation whose outputs look like the
# original package with a wrapProgram-generated launcher in bin/.
#
# Usage:
#
#   wrapPackage {
#     package        = pkgs.foo;           # required – base package
#     binName        ? package.meta.mainProgram; # optional rename: when this
#                                         #   differs from package.meta.mainProgram the
#                                         #   binary is mv'd to it before wrapping; the
#                                         #   wrap target and meta.mainProgram both use it.
#                                         #   Defaults to the upstream name (a no-op).
#     extraPaths     ? [];                 # additional derivations merged into the
#                                         #   symlinkJoin paths alongside package
#                                         #   (e.g. helper scripts to co-install)
#     inheritPath    ? false;              # keep the ambient PATH and prefix
#                                         #   runtimeInputs onto it; the default
#                                         #   clears PATH to exactly runtimeInputs
#     binaryWrapper  ? false;              # use makeBinaryWrapper instead of makeWrapper;
#                                         #   produces a compiled binary rather than a shell
#                                         #   script — required on macOS for .app bundles
#                                         #   (macOS refuses shell-script .app executables)
#                                         #   and for flags only the binary wrapper supports
#                                         #   such as --inherit-argv0
#     inheritArgv0   ? false;              # pass --inherit-argv0 to the wrap
#                                         #   call, preserving argv[0] across
#                                         #   exec (e.g. the login-shell dash);
#                                         #   requires binaryWrapper = true
#     env            ? {};                 # attrset; each becomes --set NAME value
#                                         #   (forced; overrides the environment)
#     setDefaults    ? {};                 # attrset; each becomes --set-default NAME value
#                                         #   (a default the environment can override)
#     prefix         ? {};                 # attrset; each becomes --prefix NAME : value —
#                                         #   colon-prepends onto a (possibly-unset) list
#                                         #   var at runtime without clobbering (e.g.
#                                         #   XDG_DATA_DIRS); use --set/env to force instead
#     flags          ? [];                 # raw strings; each becomes one --add-flags "…"
#     checks         ? [];                 # raw shell snippets run at build time before the
#                                         #   wrapper is generated; a non-zero exit fails the
#                                         #   build (e.g. validate the bundled config)
#     run            ? [];                 # raw shell snippets; each becomes one --run "…",
#                                         #   executed by the wrapper before it exec's the
#                                         #   binary (e.g. derive an env var at runtime)
#     runtimeInputs  ? [];                 # packages; becomes --prefix PATH : (makeBinPath …)
#     filesToPatch   ? [];                 # explicit file paths (may contain $out);
#                                         #   each service/dbus file is rewritten to
#                                         #   reference $out instead of the original
#                                         #   package store path
#     postWrap       ? [];                 # raw shell snippets appended to postBuild AFTER
#                                         #   the wrapProgram call and filesToPatch rewrites;
#                                         #   useful for post-wrap fixups (e.g. repointing an
#                                         #   .app bundle symlink at the new wrapper binary)
#     passthru       ? {};                 # forwarded to the derivation's passthru
#                                         #   (e.g. niri's providedSessions)
#   }
#
# The surface grows one conversion at a time: each new wrapped package adds only
# the option it needs (niri → runtimeInputs/filesToPatch; ntfy →
# setDefaults; zsh → env/binaryWrapper/inheritArgv0; …).
#
# filesToPatch: for each listed file, resolve the symlink to its target, copy
# the file (replacing the symlink with a writable copy) and substituteInPlace it
# to point at $out.  Assertive: a missing file or an absent package path is a
# build error, so a stale entry never goes unnoticed.
{
  lib,
  symlinkJoin,
  makeWrapper,
  makeBinaryWrapper,
}:

{
  package,
  binName ? package.meta.mainProgram,
  extraPaths ? [ ],
  inheritPath ? false,
  binaryWrapper ? false,
  inheritArgv0 ? false,
  env ? { },
  setDefaults ? { },
  prefix ? { },
  flags ? [ ],
  run ? [ ],
  runtimeInputs ? [ ],
  filesToPatch ? [ ],
  checks ? [ ],
  postWrap ? [ ],
  passthru ? { },
}:
let
  mainProgram = package.meta.mainProgram;

  # Rename the binary in $out/bin before wrapping when the caller requested a
  # different name (e.g. claude → claude-copilot for alongside-install variants).
  # binName defaults to mainProgram, so this is a no-op unless overridden.
  renameScript =
    if binName != mainProgram then "mv $out/bin/${mainProgram} $out/bin/${binName}" else "";

  # Build the wrapProgram arguments.  Each element of `lines` becomes one line
  # of a bash array literal, where newlines already separate the elements.
  lines =
    # --inherit-argv0: preserve argv[0] across exec so the login-shell dash
    # (e.g. `-zsh`) survives the wrapper exec.  A shell-script wrapper loses it
    # to the shebang re-exec, demoting login shells to non-login (issue #225).
    # Only makeBinaryWrapper supports this flag.
    lib.optional inheritArgv0 "    --inherit-argv0"
    # --set: force a value into the environment the wrapped program sees,
    # overriding whatever was present at launch.
    ++ lib.mapAttrsToList (k: v: "    --set ${lib.escapeShellArg k} ${lib.escapeShellArg v}") env
    # --set-default: bake in a value the wrapped program uses unless the same
    # variable is already present in the environment at runtime.
    ++ lib.mapAttrsToList (
      k: v: "    --set-default ${lib.escapeShellArg k} ${lib.escapeShellArg v}"
    ) setDefaults
    # --prefix: colon-prepend a value onto a (possibly-unset) list-style variable
    # at runtime without clobbering existing entries — the right tool for
    # XDG_DATA_DIRS/-style paths (unlike --set, which forces a literal value).
    ++ lib.mapAttrsToList (
      k: v: "    --prefix ${lib.escapeShellArg k} : ${lib.escapeShellArg v}"
    ) prefix
    # escapeShellArg, not double quotes: the build shell would expand a `$` in
    # the value, baking `$HOME` in as /homeless-shelter.  makeWrapper writes the
    # value into the wrapper's script text (make-wrapper.sh:201), so it still
    # word-splits at runtime — which `flags = [ "-f ${./tmux.conf}" ]` relies on.
    ++ map (f: "    --add-flags " + lib.escapeShellArg f) flags
    # --run: a command the wrapper runs before exec'ing the binary.  The snippet
    # is single-quoted so the build shell passes it to makeWrapper verbatim; any
    # $VAR / $(…) inside it is expanded only when the wrapper actually runs.
    ++ map (r: "    --run ${lib.escapeShellArg r}") run
    # PATH manipulation.  escapeShellArg keeps the value a properly quoted
    # argument in both the shell and binary wrapper cases.
    ++ (
      let
        path = lib.escapeShellArg (lib.makeBinPath runtimeInputs);
      in
      if !inheritPath then
        # --set PATH '' deliberately clears PATH so the wrapped program runs
        # against a known tool set (controlled execution environment) — emitted
        # even when runtimeInputs is empty.
        [ "    --set PATH ${path}" ]
      else
        # inheritPath=true: only prefix when there is something to add.  An
        # empty --prefix value would prepend a leading colon (empty PATH element
        # = CWD) under makeBinaryWrapper rather than being a no-op — a silent
        # security regression — so omit the line entirely instead.
        lib.optional (runtimeInputs != [ ]) "    --prefix PATH : ${path}"
    );

  # A bash array rather than one long continued command: inside ( ) a newline
  # separates elements, so no line-continuation backslashes are needed.
  wrapCall = ''
    wrapArgs=(
    ${lib.concatStringsSep "\n" lines}
    )
    wrapProgram $out/bin/${binName} "''${wrapArgs[@]}"
  '';

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

  # checks: build-time validation snippets, run before the wrapper is generated
  # so a bad bundled config fails the build (and is checked against the
  # unwrapped binary still present at $out/bin).  The build runs under `set -e`,
  # so any non-zero exit aborts.
  checkScript = lib.concatStringsSep "\n" checks;

  # postWrap: arbitrary shell snippets run after wrapProgram and filesToPatch
  # have both completed.  Useful for fixups that depend on the wrapper already
  # being in place (e.g. repointing an .app bundle symlink at the new wrapper).
  postWrapScript = lib.concatStringsSep "\n" postWrap;

  # Carry the wrapped package's version in the store name so closure-diff tools
  # show "foo-wrapped 1.2 -> 1.3" instead of "<none>".
  version = lib.getVersion package;
in
symlinkJoin {
  name = "${binName}-wrapped${lib.optionalString (version != "") "-${version}"}";
  nativeBuildInputs = [ (if binaryWrapper then makeBinaryWrapper else makeWrapper) ];
  paths = [ package ] ++ extraPaths;
  # A wrapper runs wherever what it wraps runs, and the flake filters its
  # package list on this.
  meta = {
    mainProgram = binName;
    inherit (package.meta) platforms;
  };
  inherit passthru;
  postBuild = ''
    ${checkScript}

    ${renameScript}

    ${wrapCall}

    ${patchScript}

    ${postWrapScript}
  '';
}
