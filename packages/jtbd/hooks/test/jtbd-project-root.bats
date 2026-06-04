#!/usr/bin/env bats

# P004: jtbd-enforce-edit.sh project-root check.

setup() {
  SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  HOOK="$SCRIPT_DIR/jtbd-enforce-edit.sh"
}

run_hook_with_file() {
  local file_path="$1"
  local json="{\"tool_input\":{\"file_path\":\"${file_path}\"},\"session_id\":\"test-$$\"}"
  echo "$json" | bash "$HOOK"
}

@test "jtbd project-root: absolute path outside project exits 0" {
  run run_hook_with_file "/Users/other/somewhere/file.json"
  [ "$status" -eq 0 ]
  [[ "$output" != *"BLOCKED"* ]]
}

@test "jtbd project-root: home-dir config path exits 0" {
  run run_hook_with_file "/Users/somebody/.claude/channels/discord/access.json"
  [ "$status" -eq 0 ]
  [[ "$output" != *"BLOCKED"* ]]
}

# P191: the gate must resolve docs/jtbd from the project root
# (CLAUDE_PROJECT_DIR), NOT the hook's actual runtime CWD. Claude Code can
# launch the hook with a working directory that differs from the session/
# project dir; a relative `[ -d "docs/jtbd" ]` then false-negatives and the
# fail-closed "no JTBD documentation" branch blocks legitimate edits even
# though docs/jtbd is present.
@test "jtbd project-root: detects docs/jtbd via CLAUDE_PROJECT_DIR when hook CWD differs (P191)" {
  local proj other json
  proj="$(mktemp -d)"
  other="$(mktemp -d)"        # a CWD that does NOT contain docs/jtbd
  mkdir -p "$proj/docs/jtbd"
  echo "# job" > "$proj/docs/jtbd/JTBD-001-x.md"
  json="{\"tool_input\":{\"file_path\":\"${proj}/packages/x/foo.sh\"},\"session_id\":\"test-$$\"}"
  # Fire the hook from `other` (wrong CWD) but with CLAUDE_PROJECT_DIR set to
  # the real project. Pre-fix this emitted "no JTBD documentation exists";
  # post-fix the gate is ACTIVE and denies for the missing review marker.
  run env CLAUDE_PROJECT_DIR="$proj" bash -c "cd '$other' && printf '%s' '$json' | bash '$HOOK'"
  rm -rf "$proj" "$other"
  [[ "$output" != *"no JTBD documentation exists"* ]]
  [[ "$output" == *"without JTBD review"* ]]
}

# P191 regression guard: when docs/jtbd genuinely does not exist under the
# project root, the fail-closed "no JTBD documentation" deny is preserved
# (the fix narrows the false-negative; it must not silence true-absence).
@test "jtbd project-root: genuinely-absent docs/jtbd still denies (fail-closed preserved, P191)" {
  local proj json
  proj="$(mktemp -d)"         # no docs/jtbd created
  json="{\"tool_input\":{\"file_path\":\"${proj}/foo.sh\"},\"session_id\":\"test-$$\"}"
  run env CLAUDE_PROJECT_DIR="$proj" bash -c "printf '%s' '$json' | bash '$HOOK'"
  rm -rf "$proj"
  [[ "$output" == *"no JTBD documentation exists"* ]]
}
