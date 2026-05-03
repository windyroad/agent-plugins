#!/usr/bin/env bats

# Behavioural fixture for tdd-review-test.sh per ADR-052.
# Dogfood: this file MUST be behavioural — no greps of tdd-review-test.sh
# source or review-test.md agent source. We exercise the hook with mock
# JSON tool input and assert on its emitted output (or its silence).
#
# Coverage per ADR-052 Confirmation:
#   (a) test file → emits advisory directive
#   (b) non-test file → silent
#   (c) WR_TDD_REVIEW_TEST=skip → silent
#   (d) tdd-review: structural-permitted comment → silent
#   (e) outside-PWD path → silent
#   (f) file does not exist on disk → silent
#
# @problem P081

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../.." && pwd)"
  HOOK="$REPO_ROOT/packages/tdd/hooks/tdd-review-test.sh"

  WORKDIR="$(mktemp -d)"
  ORIG_PWD="$PWD"
  cd "$WORKDIR"

  # Sample test file content — a structural assertion the agent should flag.
  STRUCTURAL_BATS_BODY='@test "skill cites P081" {
  run grep -F "P081" "$SKILL_MD"
  [ "$status" -eq 0 ]
}'

  # Sample test file content with the in-file justification comment.
  JUSTIFIED_BATS_BODY='# tdd-review: structural-permitted (justification: P012 harness primitive not yet implemented)
@test "skill cites P081" {
  run grep -F "P081" "$SKILL_MD"
  [ "$status" -eq 0 ]
}'

  # Sample TS test file with the // form of the justification comment.
  JUSTIFIED_TS_BODY='// tdd-review: structural-permitted (justification: P012 vitest harness)
import { expect, test } from "vitest";
test("skill cites P081", () => {
  expect(true).toBe(true);
});'

  # Non-test file body.
  IMPL_BODY='function foo() { return 1; }'
}

teardown() {
  cd "$ORIG_PWD"
  rm -rf "$WORKDIR"
}

# Helper — invoke the hook with a tool_input.file_path and capture output.
run_hook_with_path() {
  local path="$1"
  local json
  json=$(jq -nc --arg p "$path" '{tool_input: {file_path: $p}, session_id: "rt-test"}')
  printf '%s' "$json" | bash "$HOOK"
}

# --- (a) test file → emits advisory directive ---

@test "emits advisory when a .bats file is written" {
  local f="$WORKDIR/foo.bats"
  printf '%s\n' "$STRUCTURAL_BATS_BODY" > "$f"

  run run_hook_with_path "$f"

  [ "$status" -eq 0 ]
  [[ "$output" == *"TDD REVIEW-TEST ADVISORY"* ]]
  [[ "$output" == *"$f"* ]]
  [[ "$output" == *"review-test"* ]]
}

@test "emits advisory when a vitest .test.ts file is written" {
  local f="$WORKDIR/foo.test.ts"
  printf 'test("foo", () => {});\n' > "$f"

  run run_hook_with_path "$f"

  [ "$status" -eq 0 ]
  [[ "$output" == *"TDD REVIEW-TEST ADVISORY"* ]]
}

@test "emits advisory when a pytest test_*.py file is written" {
  local f="$WORKDIR/test_foo.py"
  printf 'def test_foo():\n    assert True\n' > "$f"

  run run_hook_with_path "$f"

  [ "$status" -eq 0 ]
  [[ "$output" == *"TDD REVIEW-TEST ADVISORY"* ]]
}

@test "emits advisory when a cucumber .feature file is written" {
  local f="$WORKDIR/checkout.feature"
  printf 'Feature: foo\n  Scenario: bar\n    Given x\n' > "$f"

  run run_hook_with_path "$f"

  [ "$status" -eq 0 ]
  [[ "$output" == *"TDD REVIEW-TEST ADVISORY"* ]]
}

# --- (b) non-test file → silent ---

@test "silent on a plain .ts implementation file" {
  local f="$WORKDIR/foo.ts"
  printf '%s\n' "$IMPL_BODY" > "$f"

  run run_hook_with_path "$f"

  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "silent on a hook .sh file" {
  local f="$WORKDIR/some-hook.sh"
  printf '#!/bin/bash\necho hi\n' > "$f"

  run run_hook_with_path "$f"

  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "silent on a .md prose file" {
  local f="$WORKDIR/README.md"
  printf '# Heading\n' > "$f"

  run run_hook_with_path "$f"

  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# --- (c) WR_TDD_REVIEW_TEST=skip → silent ---

@test "silent when WR_TDD_REVIEW_TEST=skip is set" {
  local f="$WORKDIR/foo.bats"
  printf '%s\n' "$STRUCTURAL_BATS_BODY" > "$f"

  WR_TDD_REVIEW_TEST=skip run run_hook_with_path "$f"

  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# --- (d) tdd-review: structural-permitted comment → silent ---

@test "silent when bash # tdd-review justification comment present" {
  local f="$WORKDIR/foo.bats"
  printf '%s\n' "$JUSTIFIED_BATS_BODY" > "$f"

  run run_hook_with_path "$f"

  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "silent when TS // tdd-review justification comment present" {
  local f="$WORKDIR/foo.test.ts"
  printf '%s\n' "$JUSTIFIED_TS_BODY" > "$f"

  run run_hook_with_path "$f"

  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# --- (e) outside-PWD path → silent ---

@test "silent when file path is outside PWD" {
  # Create the file in a different temp dir so it exists but is not under PWD.
  local outside
  outside="$(mktemp -d)"
  local f="$outside/foo.bats"
  printf '%s\n' "$STRUCTURAL_BATS_BODY" > "$f"

  run run_hook_with_path "$f"

  [ "$status" -eq 0 ]
  [ -z "$output" ]

  rm -rf "$outside"
}

# --- (f) file does not exist on disk → silent ---

@test "silent when file path does not exist on disk" {
  local f="$WORKDIR/nonexistent.bats"
  # Deliberately do NOT create the file.

  run run_hook_with_path "$f"

  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# --- Additional behavioural assertions ---

@test "advisory text mentions ADR-052" {
  local f="$WORKDIR/foo.bats"
  printf '%s\n' "$STRUCTURAL_BATS_BODY" > "$f"

  run run_hook_with_path "$f"

  [ "$status" -eq 0 ]
  [[ "$output" == *"ADR-052"* ]]
}

@test "advisory text mentions both escape hatches" {
  local f="$WORKDIR/foo.bats"
  printf '%s\n' "$STRUCTURAL_BATS_BODY" > "$f"

  run run_hook_with_path "$f"

  [ "$status" -eq 0 ]
  [[ "$output" == *"WR_TDD_REVIEW_TEST=skip"* ]]
  [[ "$output" == *"structural-permitted"* ]]
}

@test "exit status is always 0 (advisory, never blocking)" {
  local f="$WORKDIR/foo.bats"
  printf '%s\n' "$STRUCTURAL_BATS_BODY" > "$f"

  run run_hook_with_path "$f"
  [ "$status" -eq 0 ]

  printf '%s\n' "$JUSTIFIED_BATS_BODY" > "$f"
  run run_hook_with_path "$f"
  [ "$status" -eq 0 ]

  rm "$f"
  run run_hook_with_path "$f"
  [ "$status" -eq 0 ]
}
