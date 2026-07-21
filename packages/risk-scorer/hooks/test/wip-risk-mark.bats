#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../.." && pwd)"
  HOOK="$REPO_ROOT/packages/risk-scorer/hooks/wip-risk-mark.sh"
  ORIG_DIR="$PWD"
  TEST_DIR="$(mktemp -d)"
  TMPDIR="$TEST_DIR/tmp"
  export TMPDIR
  mkdir -p "$TMPDIR"
  mkdir -p "$TEST_DIR/repo"
  cd "$TEST_DIR/repo"
  git init -q
  git config user.email test@example.com
  git config user.name "Test User"
  printf 'base\n' > base.txt
  git add base.txt
  git commit -q -m initial
  SESSION_ID="wip-mark-$$"
}

teardown() {
  cd "$ORIG_DIR"
  rm -rf "$TEST_DIR"
}

run_hook() {
  python3 - "$SESSION_ID" <<'PY' | bash "$HOOK"
import json
import sys
print(json.dumps({
    "tool_name": "Write",
    "session_id": sys.argv[1],
    "tool_input": {"file_path": "src/example.txt"},
}))
PY
}

@test "wip-risk-mark nudges once when accumulated WIP crosses the small-batch threshold" {
  mkdir -p src
  printf 'one\n' > src/one.txt
  printf 'two\n' > src/two.txt
  printf 'three\n' > src/three.txt

  run run_hook
  [ "$status" -eq 0 ]
  [[ "$output" == *"Batching risk rising: 3 changed files"* ]]
  [[ "$output" == *"committing a coherent slice now"* ]]
  [[ "$output" == *"push and release small batches"* ]]

  run run_hook
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "wip-risk-mark stays silent below threshold" {
  mkdir -p src
  printf 'one\n' > src/one.txt
  printf 'two\n' > src/two.txt

  run run_hook
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}
