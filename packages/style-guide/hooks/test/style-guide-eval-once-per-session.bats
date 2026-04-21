#!/usr/bin/env bats

# P095 / ADR-038: style-guide-eval.sh UserPromptSubmit hook must emit
# the full MANDATORY block only on the first prompt of a session;
# subsequent prompts emit a terse reminder.

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../.." && pwd)"
  HOOK="$REPO_ROOT/packages/style-guide/hooks/style-guide-eval.sh"

  WORKDIR="$(mktemp -d)"
  mkdir -p "$WORKDIR/docs"
  : > "$WORKDIR/docs/STYLE-GUIDE.md"

  SID="sg-eval-test-$$-$RANDOM"
}

teardown() {
  rm -f "/tmp/style-guide-announced-${SID}"
  rm -f "/tmp/style-guide-announced-${SID}-alt"
  rm -rf "$WORKDIR"
}

run_hook() {
  local sid="$1"
  (cd "$WORKDIR" && echo "{\"session_id\":\"$sid\"}" | bash "$HOOK")
}

@test "style-guide-eval: first invocation emits the full MANDATORY block" {
  run run_hook "$SID"
  [ "$status" -eq 0 ]
  [ "${#output}" -gt 400 ]
  [[ "$output" == *"MANDATORY STYLE GUIDE CHECK"* ]]
  [[ "$output" == *"wr-style-guide:agent"* ]]
}

@test "style-guide-eval: first invocation writes the announcement marker" {
  run run_hook "$SID"
  [ -f "/tmp/style-guide-announced-${SID}" ]
}

@test "style-guide-eval: second invocation emits only a terse reminder" {
  run_hook "$SID" >/dev/null
  run run_hook "$SID"
  [ "${#output}" -lt 250 ]
  [[ "$output" == *"style-guide"* ]] || [[ "$output" == *"STYLE"* ]]
  [[ "$output" == *"wr-style-guide:agent"* ]]
  [[ "$output" != *"REQUIRED ACTIONS:"* ]]
}

@test "style-guide-eval: terse reminder preserves the MANDATORY signal word" {
  run_hook "$SID" >/dev/null
  run run_hook "$SID"
  [[ "$output" == *"MANDATORY"* ]] || [[ "$output" == *"REQUIRED"* ]] || [[ "$output" == *"NON-OPTIONAL"* ]]
}

@test "style-guide-eval: terse reminder names the trigger artifact" {
  run_hook "$SID" >/dev/null
  run run_hook "$SID"
  [[ "$output" == *"STYLE-GUIDE.md"* ]]
}

@test "style-guide-eval: different session_id re-emits the full block" {
  run_hook "$SID" >/dev/null
  local SID2="${SID}-alt"
  run run_hook "$SID2"
  [ "${#output}" -gt 400 ]
  [[ "$output" == *"MANDATORY STYLE GUIDE CHECK"* ]]
  rm -f "/tmp/style-guide-announced-${SID2}"
}

@test "style-guide-eval: empty session_id emits the full block and writes no marker" {
  run run_hook ""
  [ "${#output}" -gt 400 ]
  [[ "$output" == *"MANDATORY STYLE GUIDE CHECK"* ]]
  [ ! -f "/tmp/style-guide-announced-" ]
}
