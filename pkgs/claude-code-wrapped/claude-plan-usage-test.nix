{
  callPackage,
  gitMinimal,
  lib,
  libfaketime,
  runCommand,
}:

let
  claude-plan-usage = callPackage ./claude-plan-usage.nix { };
in
runCommand "claude-plan-usage-test"
  {
    nativeBuildInputs = [
      gitMinimal
      libfaketime
    ];
  }
  ''
    export HOME=$TMPDIR
    export TZ=UTC

    # The statusline prints the checked-out branch, so it needs a repo with a
    # known one; faketime pins "now" so the pace arithmetic against the
    # fixtures' reset timestamps is reproducible.
    git init --quiet --initial-branch=my-branch "$TMPDIR/repo"
    cd "$TMPDIR/repo"

    for fixture in ${./tests}/*.json; do
      expected=''${fixture%.json}.expected
      # Escapes are spelled out so a failing diff stays readable.
      faketime -f '@2026-08-21 12:00:00' ${lib.getExe claude-plan-usage} \
        <"$fixture" |
        sed 's/\x1b/<ESC>/g' >actual
      diff --unified "$expected" actual
    done

    touch $out
  ''
