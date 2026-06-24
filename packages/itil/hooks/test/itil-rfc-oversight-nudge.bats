#!/usr/bin/env bats

# P378/RFC-030: itil-rfc-oversight-nudge.sh (SessionStart) emits a one-line
# nudge when RFCs lack the human-oversight marker, is silent when none do, and
# self-suppresses under the shared AFK guard (WR_SUPPRESS_OVERSIGHT_NUDGE=1).
# Behavioural — exercises the hook against fixture docs/rfcs/ trees. Clone of
# the architect/jtbd oversight-nudge contract (ADR-066/068).

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../.." && pwd)"
  HOOK="$REPO_ROOT/packages/itil/hooks/itil-rfc-oversight-nudge.sh"
  PLUGIN_ROOT="$REPO_ROOT/packages/itil"
  DIR="$(mktemp -d)"
  mkdir -p "$DIR/docs/rfcs"
}

teardown() { rm -rf "$DIR"; }

mk_unconfirmed() {
  { echo "---"; echo "status: proposed"; echo "human-oversight: unconfirmed"; echo "---"; echo "# $1"; } \
    > "$DIR/docs/rfcs/$1"
}
mk_confirmed() {
  { echo "---"; echo "status: proposed"; echo "human-oversight: confirmed"; echo "---"; echo "# $1"; } \
    > "$DIR/docs/rfcs/$1"
}

run_hook() { run env CLAUDE_PROJECT_DIR="$DIR" CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" "$@" bash "$HOOK"; }

@test "emits a count line when there are unoversighted RFCs" {
  mk_unconfirmed "RFC-201-foo.proposed.md"
  mk_unconfirmed "RFC-202-bar.proposed.md"
  run env CLAUDE_PROJECT_DIR="$DIR" CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" bash "$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" == *"2 RFCs lack human oversight"* ]]
  [[ "$output" == *"/wr-itil:manage-rfc"* ]]
}

@test "singular wording for exactly one unoversighted RFC" {
  mk_unconfirmed "RFC-201-foo.proposed.md"
  run env CLAUDE_PROJECT_DIR="$DIR" CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" bash "$HOOK"
  [[ "$output" == *"1 RFC lacks human oversight"* ]]
}

@test "silent when every RFC is confirmed" {
  mk_confirmed "RFC-201-foo.proposed.md"
  run env CLAUDE_PROJECT_DIR="$DIR" CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" bash "$HOOK"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "excludes superseded and closed RFCs from the count" {
  mk_unconfirmed "RFC-201-foo.superseded.md"
  mk_unconfirmed "RFC-202-bar.closed.md"
  run env CLAUDE_PROJECT_DIR="$DIR" CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" bash "$HOOK"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "shared AFK guard suppresses the nudge entirely" {
  mk_unconfirmed "RFC-201-foo.proposed.md"
  run env WR_SUPPRESS_OVERSIGHT_NUDGE=1 CLAUDE_PROJECT_DIR="$DIR" CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" bash "$HOOK"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "guard value other than 1 does not suppress" {
  mk_unconfirmed "RFC-201-foo.proposed.md"
  run env WR_SUPPRESS_OVERSIGHT_NUDGE=yes CLAUDE_PROJECT_DIR="$DIR" CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" bash "$HOOK"
  [[ "$output" == *"lack"*"human oversight"* ]] || [[ "$output" == *"lacks human oversight"* ]]
}

@test "silent when docs/rfcs does not exist (framework not adopted)" {
  rm -rf "$DIR/docs/rfcs"
  run env CLAUDE_PROJECT_DIR="$DIR" CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" bash "$HOOK"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}
