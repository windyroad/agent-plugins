#!/usr/bin/env bats

# P095 / ADR-038: jtbd-eval.sh UserPromptSubmit hook must emit the full
# MANDATORY block only on the first prompt of a session; subsequent
# prompts emit a terse reminder.

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../.." && pwd)"
  HOOK="$REPO_ROOT/packages/jtbd/hooks/jtbd-eval.sh"

  WORKDIR="$(mktemp -d)"
  mkdir -p "$WORKDIR/docs/jtbd"
  : > "$WORKDIR/docs/jtbd/README.md"

  SID="jtbd-eval-test-$$-$RANDOM"
}

teardown() {
  rm -f "/tmp/jtbd-announced-${SID}"
  rm -f "/tmp/jtbd-announced-${SID}-alt"
  rm -rf "$WORKDIR"
}

run_hook() {
  local sid="$1"
  (cd "$WORKDIR" && echo "{\"session_id\":\"$sid\"}" | bash "$HOOK")
}

@test "jtbd-eval: first invocation emits the full MANDATORY block" {
  run run_hook "$SID"
  [ "$status" -eq 0 ]
  [ "${#output}" -gt 400 ]
  [[ "$output" == *"MANDATORY JTBD CHECK"* ]]
  [[ "$output" == *"wr-jtbd:agent"* ]]
  [[ "$output" == *"SCOPE:"* ]]
}

@test "jtbd-eval: first invocation writes the announcement marker" {
  run run_hook "$SID"
  [ -f "/tmp/jtbd-announced-${SID}" ]
}

@test "jtbd-eval: second invocation emits only a terse reminder" {
  run_hook "$SID" >/dev/null
  run run_hook "$SID"
  [ "$status" -eq 0 ]
  [ "${#output}" -lt 250 ]
  [[ "$output" == *"jtbd"* ]] || [[ "$output" == *"JTBD"* ]]
  [[ "$output" == *"wr-jtbd:agent"* ]]
  [[ "$output" != *"Does NOT apply to"* ]]
}

@test "jtbd-eval: terse reminder preserves the MANDATORY signal word" {
  run_hook "$SID" >/dev/null
  run run_hook "$SID"
  [[ "$output" == *"MANDATORY"* ]] || [[ "$output" == *"REQUIRED"* ]] || [[ "$output" == *"NON-OPTIONAL"* ]]
}

@test "jtbd-eval: terse reminder names the trigger artifact" {
  run_hook "$SID" >/dev/null
  run run_hook "$SID"
  [[ "$output" == *"docs/jtbd"* ]]
}

@test "jtbd-eval: different session_id re-emits the full block" {
  run_hook "$SID" >/dev/null
  local SID2="${SID}-alt"
  run run_hook "$SID2"
  [ "${#output}" -gt 400 ]
  [[ "$output" == *"MANDATORY JTBD CHECK"* ]]
  rm -f "/tmp/jtbd-announced-${SID2}"
}

@test "jtbd-eval: empty session_id emits the full block and writes no marker" {
  run run_hook ""
  [ "${#output}" -gt 400 ]
  [[ "$output" == *"MANDATORY JTBD CHECK"* ]]
  [ ! -f "/tmp/jtbd-announced-" ]
}

@test "jtbd-eval: absent docs/jtbd/ emits the no-docs NOTE (unchanged by this ADR)" {
  local NO_JTBD="$(mktemp -d)"
  run bash -c "cd '$NO_JTBD' && echo '{\"session_id\":\"$SID\"}' | bash '$HOOK'"
  [[ "$output" == *"no docs/jtbd/ directory"* ]]
  [[ "$output" != *"MANDATORY JTBD CHECK"* ]]
  rm -rf "$NO_JTBD"
}
