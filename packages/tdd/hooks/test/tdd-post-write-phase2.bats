#!/usr/bin/env bats

# P096 Phase 2: tdd-post-write.sh injection trims.
#
# Three behaviours covered:
# 1. Silent on GREEN-unchanged (OLD=GREEN, NEW=GREEN -> exit 0 with no output).
# 2. Hash-based dedupe of RED test output across consecutive RED edits with
#    identical last-50-lines output.
# 3. GREEN ACTION line dropped (the standing prose "Tests are passing... You
#    may refactor..." is no longer emitted on GREEN transitions).
#
# Per ADR-038 progressive-disclosure pattern: dynamic state on transition
# stays; standing prose / repeated content is suppressed.

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../.." && pwd)"
  HOOK="$REPO_ROOT/packages/tdd/hooks/tdd-post-write.sh"

  WORKDIR="$(mktemp -d)"
  # Use relative paths in the hook input so dirname/basename matching in
  # tdd_find_test_for_impl behaves predictably across mktemp prefixes.
  TEST_FILE="src/widget.test.ts"
  IMPL_FILE="src/widget.ts"
  mkdir -p "$WORKDIR/src"
  : > "$WORKDIR/$TEST_FILE"
  : > "$WORKDIR/$IMPL_FILE"

  SID="tdd-post-write-phase2-$$-$RANDOM"
}

teardown() {
  rm -rf "/tmp/tdd-state-${SID}" \
         "/tmp/tdd-test-files-${SID}" \
         "/tmp/tdd-test-stdout-${SID}" \
         "/tmp/tdd-stdout-hash-${SID}-"*
  rm -rf "$WORKDIR"
}

# Write a package.json whose `test` script prints fixed stdout then exits
# 0 (pass) or 1 (fail). Uses `true`/`false` as the exit primitive so the
# trailing test-file argument injected by `npm test -- <file>` is absorbed
# without triggering "exit: too many arguments".
write_pkg_json() {
  local exit_code="${1:-0}"
  local stdout_text="${2:-}"
  local exit_cmd="true"
  [ "$exit_code" -ne 0 ] && exit_cmd="false"
  cat > "$WORKDIR/package.json" <<JSON
{
  "name": "test-tdd-post-write-phase2",
  "version": "0.0.0",
  "scripts": {
    "test": "printf '%s\\n' '${stdout_text}' && ${exit_cmd}"
  }
}
JSON
}

run_hook_for_impl() {
  local sid="$1"
  local impl="$2"
  (cd "$WORKDIR" && \
    echo "{\"session_id\":\"$sid\",\"tool_input\":{\"file_path\":\"$impl\"}}" | \
    bash "$HOOK")
}

run_hook_for_test() {
  local sid="$1"
  local test_file="$2"
  (cd "$WORKDIR" && \
    echo "{\"session_id\":\"$sid\",\"tool_input\":{\"file_path\":\"$test_file\"}}" | \
    bash "$HOOK")
}

# Register the test file in the tracked set by firing the hook on it once.
# This is the prerequisite for tdd_find_test_for_impl to associate the impl
# with the test on subsequent impl-file invocations.
register_test_file() {
  local sid="$1"
  local test_file="$2"
  run_hook_for_test "$sid" "$test_file" >/dev/null
}

# --- Behaviour 1: silent on GREEN-unchanged ---

@test "tdd-post-write: GREEN -> GREEN unchanged emits nothing" {
  write_pkg_json 0 "all good"
  # First invocation: writing the test file enters tracked state, runs
  # the test, classifies as GREEN. Output expected (we discard it).
  register_test_file "$SID" "$TEST_FILE"

  # Second invocation: edit impl. Test still passes. OLD == NEW == GREEN.
  run run_hook_for_impl "$SID" "$IMPL_FILE"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "tdd-post-write: GREEN -> GREEN unchanged exits 0 with no STATE UPDATE" {
  write_pkg_json 0 "all good"
  register_test_file "$SID" "$TEST_FILE"

  run run_hook_for_impl "$SID" "$IMPL_FILE"
  [[ "$output" != *"TDD STATE UPDATE"* ]]
  [[ "$output" != *"State unchanged"* ]]
}

# --- Behaviour 2: dedupe RED test output across consecutive identical RED edits ---

@test "tdd-post-write: consecutive RED with identical output suppresses second emit's test-output block" {
  write_pkg_json 1 "FAIL_assertion_mismatch_line_7"
  register_test_file "$SID" "$TEST_FILE"

  # Second invocation: same impl, same failing test, same output. Still
  # RED. Hash matches the previous emission, so the output block is
  # suppressed (replaced with the "unchanged" marker).
  run run_hook_for_impl "$SID" "$IMPL_FILE"
  [[ "$output" == *"TDD STATE UPDATE"* ]]
  [[ "$output" == *"Test output unchanged from previous emission"* ]]
  [[ "$output" != *"Test output (last 50 lines):"* ]]
}

@test "tdd-post-write: RED with changed output emits the full body" {
  write_pkg_json 1 "FAIL_assertion_mismatch_line_7"
  register_test_file "$SID" "$TEST_FILE"
  run_hook_for_impl "$SID" "$IMPL_FILE" >/dev/null

  # Different output: re-run with a different stdout. Hash mismatches,
  # full output block re-emits.
  write_pkg_json 1 "FAIL_assertion_mismatch_line_9"
  run run_hook_for_impl "$SID" "$IMPL_FILE"
  [[ "$output" == *"Test output (last 50 lines):"* ]]
  [[ "$output" == *"FAIL_assertion_mismatch_line_9"* ]]
  [[ "$output" != *"Test output unchanged"* ]]
}

# --- Behaviour 3: GREEN ACTION line dropped ---

@test "tdd-post-write: RED -> GREEN transition emits STATE UPDATE but no GREEN ACTION line" {
  # Drive RED first.
  write_pkg_json 1 "FAIL"
  register_test_file "$SID" "$TEST_FILE"
  # Now transition to GREEN.
  write_pkg_json 0 "ok"
  run run_hook_for_impl "$SID" "$IMPL_FILE"
  [[ "$output" == *"TDD STATE UPDATE"* ]]
  [[ "$output" == *"State transition: RED -> GREEN"* ]]
  [[ "$output" != *"You may refactor"* ]]
  [[ "$output" != *"ACTION: Tests are passing"* ]]
}

# --- Negative: RED keeps its actionable ACTION line ---

@test "tdd-post-write: IDLE -> RED still emits ACTION: Tests are failing" {
  write_pkg_json 1 "FAIL"
  run run_hook_for_test "$SID" "$TEST_FILE"
  [[ "$output" == *"ACTION: Tests are failing"* ]]
}

# --- Negative: empty session_id falls through cleanly ---

@test "tdd-post-write: empty session_id exits 0 without crashing" {
  write_pkg_json 0 "ok"
  run bash -c "cd '$WORKDIR' && echo '{\"session_id\":\"\",\"tool_input\":{\"file_path\":\"$IMPL_FILE\"}}' | bash '$HOOK'"
  [ "$status" -eq 0 ]
}
