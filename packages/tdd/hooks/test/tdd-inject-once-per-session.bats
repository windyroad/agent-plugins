#!/usr/bin/env bats

# P095 / ADR-038: tdd-inject.sh UserPromptSubmit hook is the special
# case in the cluster — dynamic TDD state (IDLE/RED/GREEN/BLOCKED +
# tracked test files list) must be emitted on every prompt regardless
# of announcement state. Only the static prose (STATE RULES, WORKFLOW,
# IMPORTANT blocks) is gated by the once-per-session marker.
#
# Per ADR-038 tdd-inject carve-out.

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../.." && pwd)"
  HOOK="$REPO_ROOT/packages/tdd/hooks/tdd-inject.sh"

  # Stub project working dir with a test script in package.json so the
  # hook does NOT fall through to the "no test script" branch.
  WORKDIR="$(mktemp -d)"
  cat > "$WORKDIR/package.json" <<'JSON'
{ "name": "test-tdd", "version": "0.0.0", "scripts": { "test": "echo pass" } }
JSON

  SID="tdd-inject-test-$$-$RANDOM"
}

teardown() {
  rm -f "/tmp/tdd-announced-${SID}"
  rm -f "/tmp/tdd-announced-${SID}-alt"
  rm -rf "$WORKDIR"
}

run_hook() {
  local sid="$1"
  (cd "$WORKDIR" && echo "{\"session_id\":\"$sid\"}" | bash "$HOOK")
}

@test "tdd-inject: first invocation emits the full MANDATORY block with STATE RULES" {
  run run_hook "$SID"
  [ "$status" -eq 0 ]
  [ "${#output}" -gt 1000 ]
  [[ "$output" == *"MANDATORY TDD ENFORCEMENT"* ]]
  [[ "$output" == *"STATE RULES"* ]]
  [[ "$output" == *"WORKFLOW:"* ]]
  [[ "$output" == *"IMPORTANT:"* ]]
}

@test "tdd-inject: first invocation writes the announcement marker" {
  run run_hook "$SID"
  [ -f "/tmp/tdd-announced-${SID}" ]
}

@test "tdd-inject: subsequent invocations drop the static prose (STATE RULES / WORKFLOW / IMPORTANT)" {
  run_hook "$SID" >/dev/null
  run run_hook "$SID"
  [ "$status" -eq 0 ]
  [ "${#output}" -lt 500 ]
  [[ "$output" != *"STATE RULES"* ]]
  [[ "$output" != *"WORKFLOW:"* ]]
  [[ "$output" != *"IMPORTANT:"* ]]
}

@test "tdd-inject: subsequent invocations PRESERVE dynamic state (current TDD state line)" {
  run_hook "$SID" >/dev/null
  run run_hook "$SID"
  [ "$status" -eq 0 ]
  # Dynamic state line must still appear per-prompt. With no test files
  # tracked yet, the overall state is IDLE.
  [[ "$output" == *"IDLE"* ]]
  # And the terse reminder itself carries the MANDATORY signal + the
  # delegation affordance.
  [[ "$output" == *"MANDATORY"* ]] || [[ "$output" == *"REQUIRED"* ]] || [[ "$output" == *"NON-OPTIONAL"* ]]
  [[ "$output" == *"TDD"* ]]
}

@test "tdd-inject: terse reminder names the trigger artifact" {
  run_hook "$SID" >/dev/null
  run run_hook "$SID"
  # Trigger for this gate is the test script in package.json.
  [[ "$output" == *"test script"* ]] || [[ "$output" == *"package.json"* ]]
}

@test "tdd-inject: different session_id re-emits the full static block" {
  run_hook "$SID" >/dev/null
  local SID2="${SID}-alt"
  run run_hook "$SID2"
  [ "${#output}" -gt 1000 ]
  [[ "$output" == *"STATE RULES"* ]]
  rm -f "/tmp/tdd-announced-${SID2}"
}

@test "tdd-inject: empty session_id emits the full static block and writes no marker" {
  run run_hook ""
  [ "${#output}" -gt 1000 ]
  [[ "$output" == *"STATE RULES"* ]]
  [ ! -f "/tmp/tdd-announced-" ]
}

@test "tdd-inject: no-test-script fallback branch is unchanged by this ADR" {
  local NO_TEST="$(mktemp -d)"
  cat > "$NO_TEST/package.json" <<'JSON'
{ "name": "no-test", "version": "0.0.0" }
JSON
  run bash -c "cd '$NO_TEST' && echo '{\"session_id\":\"$SID\"}' | bash '$HOOK'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"MANDATORY TDD ENFORCEMENT"* ]]
  [[ "$output" == *"NO test script"* ]]
  rm -rf "$NO_TEST"
}
