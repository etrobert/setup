{
  deploy-gate,
  gitMinimal,
  lib,
  runCommand,
}:

runCommand "deploy-gate-test" { nativeBuildInputs = [ gitMinimal ]; } ''
  gate=${lib.getExe deploy-gate}

  export HOME=$TMPDIR
  export GIT_AUTHOR_NAME=test GIT_AUTHOR_EMAIL=test@example.com
  export GIT_COMMITTER_NAME=test GIT_COMMITTER_EMAIL=test@example.com

  export STATE_DIRECTORY=$TMPDIR/state
  export DEPLOY_URL=$TMPDIR/remote.git
  mkdir -p "$STATE_DIRECTORY"
  git init --quiet --bare --initial-branch=deploy "$DEPLOY_URL"
  git init --quiet --initial-branch=deploy "$TMPDIR/src"

  publish() {
    git -C "$TMPDIR/src" commit --quiet --allow-empty --message "$1"
    git -C "$TMPDIR/src" push --quiet "$DEPLOY_URL" deploy
    git -C "$TMPDIR/src" rev-parse HEAD
  }

  # Runs the gate and asserts its exit status; systemd reads that status as the
  # ExecCondition verdict, so it is the contract under test.
  expect() {
    expected=$1
    shift
    status=0
    "$gate" "$@" || status=$?
    [ "$status" = "$expected" ] ||
      fail "$* : expected exit $expected, got $status"
  }

  expect_rev() {
    actual=$(cat "$STATE_DIRECTORY/$1" 2>/dev/null || echo "<missing>")
    [ "$actual" = "$2" ] || fail "$1: expected $2, got $actual"
  }

  fail() {
    echo "FAIL: $*" >&2
    exit 1
  }

  rev1=$(publish one)

  # Nothing attempted yet: the deploy rev is new, so the upgrade may run.
  expect 0 check
  expect_rev pending-rev "$rev1"

  # record promotes the pending rev; a second check then skips it.
  expect 0 record
  expect_rev last-attempted-rev "$rev1"
  [ ! -e "$STATE_DIRECTORY/pending-rev" ] || fail "record left pending-rev behind"
  expect 1 check

  # A new deploy rev re-opens the gate.
  rev2=$(publish two)
  expect 0 check
  expect_rev pending-rev "$rev2"
  expect 0 record
  expect_rev last-attempted-rev "$rev2"

  # ExecStopPost runs even when ExecCondition skipped the unit, so record with
  # no pending rev must succeed and leave the recorded rev alone.
  expect 0 record
  expect_rev last-attempted-rev "$rev2"

  # An unresolvable deploy ref skips rather than upgrading whatever is current.
  git init --quiet --bare "$TMPDIR/empty.git"
  export DEPLOY_URL=$TMPDIR/empty.git
  expect 1 check

  expect 2 bogus-subcommand

  touch $out
''
