#!/usr/bin/env bats

# Tests for tdd-gate.sh shared library functions

setup() {
  SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  source "$SCRIPT_DIR/lib/tdd-gate.sh"
  TEST_SESSION="test-$$-$BATS_TEST_NUMBER"
}

teardown() {
  tdd_cleanup "$TEST_SESSION" 2>/dev/null || true
  rm -f "/tmp/tdd-setup-active-${TEST_SESSION}"
}

# --- tdd_classify_file ---

@test "classify_file: .test.ts is test" {
  result=$(tdd_classify_file "src/utils.test.ts")
  [ "$result" = "test" ]
}

@test "classify_file: .spec.jsx is test" {
  result=$(tdd_classify_file "src/App.spec.jsx")
  [ "$result" = "test" ]
}

@test "classify_file: __tests__ directory is test" {
  result=$(tdd_classify_file "src/__tests__/utils.ts")
  [ "$result" = "test" ]
}

@test "classify_file: .config.ts is exempt" {
  result=$(tdd_classify_file "vitest.config.ts")
  [ "$result" = "exempt" ]
}

@test "classify_file: .setup.ts is exempt" {
  result=$(tdd_classify_file "vitest.setup.ts")
  [ "$result" = "exempt" ]
}

@test "classify_file: .json is exempt" {
  result=$(tdd_classify_file "package.json")
  [ "$result" = "exempt" ]
}

@test "classify_file: .css is exempt" {
  result=$(tdd_classify_file "src/styles.css")
  [ "$result" = "exempt" ]
}

@test "classify_file: .md is exempt" {
  result=$(tdd_classify_file "README.md")
  [ "$result" = "exempt" ]
}

@test "classify_file: .sh is exempt" {
  result=$(tdd_classify_file "scripts/build.sh")
  [ "$result" = "exempt" ]
}

@test "classify_file: .ts is impl" {
  result=$(tdd_classify_file "src/utils.ts")
  [ "$result" = "impl" ]
}

@test "classify_file: .tsx is impl" {
  result=$(tdd_classify_file "src/App.tsx")
  [ "$result" = "impl" ]
}

@test "classify_file: .js is impl" {
  result=$(tdd_classify_file "src/index.js")
  [ "$result" = "impl" ]
}

@test "classify_file: unknown extension is exempt" {
  result=$(tdd_classify_file "Dockerfile")
  [ "$result" = "exempt" ]
}

# --- tdd_has_test_script ---

@test "has_test_script: returns false when no package.json" {
  cd "$(mktemp -d)"
  run tdd_has_test_script
  [ "$status" -ne 0 ]
}

@test "has_test_script: returns false for default npm test script" {
  local tmpdir=$(mktemp -d)
  echo '{"scripts":{"test":"echo \"Error: no test specified\" && exit 1"}}' > "$tmpdir/package.json"
  cd "$tmpdir"
  run tdd_has_test_script
  [ "$status" -ne 0 ]
  rm -rf "$tmpdir"
}

@test "has_test_script: returns true for real test script" {
  local tmpdir=$(mktemp -d)
  echo '{"scripts":{"test":"vitest"}}' > "$tmpdir/package.json"
  cd "$tmpdir"
  run tdd_has_test_script
  [ "$status" -eq 0 ]
  rm -rf "$tmpdir"
}

# --- tdd state ---

@test "read_state: returns IDLE when no state file" {
  result=$(tdd_read_state "$TEST_SESSION")
  [ "$result" = "IDLE" ]
}

@test "write_state and read_state roundtrip" {
  tdd_write_state "$TEST_SESSION" "RED"
  result=$(tdd_read_state "$TEST_SESSION")
  [ "$result" = "RED" ]
}

@test "cleanup removes state files" {
  tdd_write_state "$TEST_SESSION" "GREEN"
  tdd_cleanup "$TEST_SESSION"
  result=$(tdd_read_state "$TEST_SESSION")
  [ "$result" = "IDLE" ]
}

@test "cleanup removes setup marker" {
  touch "/tmp/tdd-setup-active-${TEST_SESSION}"
  tdd_cleanup "$TEST_SESSION"
  [ ! -f "/tmp/tdd-setup-active-${TEST_SESSION}" ]
}
