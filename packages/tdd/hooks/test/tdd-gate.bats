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

# --- tdd_classify_file: Cucumber .feature files ---

@test "classify_file: .feature file is test" {
  result=$(tdd_classify_file "features/checkout.feature")
  [ "$result" = "test" ]
}

@test "classify_file: nested .feature file is test" {
  result=$(tdd_classify_file "src/features/login.feature")
  [ "$result" = "test" ]
}

# --- tdd_find_test_for_impl: Cucumber step_definitions pairing ---

@test "find_test_for_impl: step definitions associate with .feature file" {
  tdd_add_test_file "$TEST_SESSION" "features/checkout.feature"
  result=$(tdd_find_test_for_impl "$TEST_SESSION" "features/step_definitions/checkout.steps.js")
  [ "$result" = "features/checkout.feature" ]
}

@test "find_test_for_impl: step definitions with .steps.ts associate with .feature file" {
  tdd_add_test_file "$TEST_SESSION" "features/login.feature"
  result=$(tdd_find_test_for_impl "$TEST_SESSION" "features/step_definitions/login.steps.ts")
  [ "$result" = "features/login.feature" ]
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

# --- Per-test-file state ---

@test "read_state: returns IDLE when no state exists for test file" {
  result=$(tdd_read_state "$TEST_SESSION" "src/Hero.test.tsx")
  [ "$result" = "IDLE" ]
}

@test "write_state and read_state roundtrip for a specific test file" {
  tdd_write_state "$TEST_SESSION" "src/Hero.test.tsx" "RED"
  result=$(tdd_read_state "$TEST_SESSION" "src/Hero.test.tsx")
  [ "$result" = "RED" ]
}

@test "per-file state: different test files have independent states" {
  tdd_write_state "$TEST_SESSION" "src/Hero.test.tsx" "GREEN"
  tdd_write_state "$TEST_SESSION" "src/Countdown.test.tsx" "RED"

  hero_state=$(tdd_read_state "$TEST_SESSION" "src/Hero.test.tsx")
  countdown_state=$(tdd_read_state "$TEST_SESSION" "src/Countdown.test.tsx")

  [ "$hero_state" = "GREEN" ]
  [ "$countdown_state" = "RED" ]
}

@test "per-file state: BLOCKED on one test does not affect another" {
  tdd_write_state "$TEST_SESSION" "src/Hero.test.tsx" "GREEN"
  tdd_write_state "$TEST_SESSION" "src/Countdown.test.tsx" "BLOCKED"

  hero_state=$(tdd_read_state "$TEST_SESSION" "src/Hero.test.tsx")
  [ "$hero_state" = "GREEN" ]
}

@test "cleanup removes all per-file state" {
  tdd_write_state "$TEST_SESSION" "src/Hero.test.tsx" "RED"
  tdd_write_state "$TEST_SESSION" "src/Countdown.test.tsx" "GREEN"
  tdd_cleanup "$TEST_SESSION"

  result=$(tdd_read_state "$TEST_SESSION" "src/Hero.test.tsx")
  [ "$result" = "IDLE" ]
  result=$(tdd_read_state "$TEST_SESSION" "src/Countdown.test.tsx")
  [ "$result" = "IDLE" ]
}

@test "cleanup removes setup marker" {
  touch "/tmp/tdd-setup-active-${TEST_SESSION}"
  tdd_cleanup "$TEST_SESSION"
  [ ! -f "/tmp/tdd-setup-active-${TEST_SESSION}" ]
}

# --- Test file tracking ---

@test "add_test_file and get_test_files roundtrip" {
  tdd_add_test_file "$TEST_SESSION" "src/Hero.test.tsx"
  result=$(tdd_get_test_files "$TEST_SESSION")
  [ "$result" = "src/Hero.test.tsx" ]
}

@test "add_test_file deduplicates" {
  tdd_add_test_file "$TEST_SESSION" "src/Hero.test.tsx"
  tdd_add_test_file "$TEST_SESSION" "src/Hero.test.tsx"
  local count
  count=$(tdd_get_test_files "$TEST_SESSION" | wc -l | tr -d ' ')
  [ "$count" -eq 1 ]
}

# --- Impl-to-test association ---

@test "find_test_for_impl: Hero.tsx associates with tracked Hero.test.tsx" {
  tdd_add_test_file "$TEST_SESSION" "src/Hero.test.tsx"
  result=$(tdd_find_test_for_impl "$TEST_SESSION" "src/Hero.tsx")
  [ "$result" = "src/Hero.test.tsx" ]
}

@test "find_test_for_impl: utils.ts associates with tracked utils.test.ts" {
  tdd_add_test_file "$TEST_SESSION" "src/utils.test.ts"
  result=$(tdd_find_test_for_impl "$TEST_SESSION" "src/utils.ts")
  [ "$result" = "src/utils.test.ts" ]
}

@test "suggest_test_path: Hero.tsx suggests Hero.test.tsx" {
  result=$(tdd_suggest_test_path "src/Hero.tsx")
  [ "$result" = "src/Hero.test.tsx" ]
}

@test "suggest_test_path: utils.ts suggests utils.test.ts" {
  result=$(tdd_suggest_test_path "src/utils.ts")
  [ "$result" = "src/utils.test.ts" ]
}

@test "find_test_for_impl: prefers tracked .test over .spec" {
  tdd_add_test_file "$TEST_SESSION" "src/Hero.spec.tsx"
  result=$(tdd_find_test_for_impl "$TEST_SESSION" "src/Hero.tsx")
  [ "$result" = "src/Hero.spec.tsx" ]
}

@test "find_test_for_impl: finds __tests__ variant when tracked" {
  tdd_add_test_file "$TEST_SESSION" "src/__tests__/Hero.test.tsx"
  result=$(tdd_find_test_for_impl "$TEST_SESSION" "src/Hero.tsx")
  [ "$result" = "src/__tests__/Hero.test.tsx" ]
}

@test "find_test_for_impl: returns empty when no test tracked" {
  result=$(tdd_find_test_for_impl "$TEST_SESSION" "src/Unknown.tsx")
  [ -z "$result" ]
}

# --- State for impl files (via association) ---

@test "read_state_for_impl: returns IDLE when no associated test" {
  result=$(tdd_read_state_for_impl "$TEST_SESSION" "src/Hero.tsx")
  [ "$result" = "IDLE" ]
}

@test "read_state_for_impl: returns associated test's state" {
  tdd_add_test_file "$TEST_SESSION" "src/Hero.test.tsx"
  tdd_write_state "$TEST_SESSION" "src/Hero.test.tsx" "RED"
  result=$(tdd_read_state_for_impl "$TEST_SESSION" "src/Hero.tsx")
  [ "$result" = "RED" ]
}

@test "read_state_for_impl: Hero GREEN while Countdown BLOCKED" {
  tdd_add_test_file "$TEST_SESSION" "src/Hero.test.tsx"
  tdd_add_test_file "$TEST_SESSION" "src/Countdown.test.tsx"
  tdd_write_state "$TEST_SESSION" "src/Hero.test.tsx" "GREEN"
  tdd_write_state "$TEST_SESSION" "src/Countdown.test.tsx" "BLOCKED"

  hero=$(tdd_read_state_for_impl "$TEST_SESSION" "src/Hero.tsx")
  countdown=$(tdd_read_state_for_impl "$TEST_SESSION" "src/Countdown.tsx")

  [ "$hero" = "GREEN" ]
  [ "$countdown" = "BLOCKED" ]
}

# --- get_all_states ---

@test "get_all_states: lists all test files with their states" {
  tdd_add_test_file "$TEST_SESSION" "src/Hero.test.tsx"
  tdd_add_test_file "$TEST_SESSION" "src/Countdown.test.tsx"
  tdd_write_state "$TEST_SESSION" "src/Hero.test.tsx" "GREEN"
  tdd_write_state "$TEST_SESSION" "src/Countdown.test.tsx" "RED"

  result=$(tdd_get_all_states "$TEST_SESSION")
  echo "$result" | grep -q "src/Hero.test.tsx:GREEN"
  echo "$result" | grep -q "src/Countdown.test.tsx:RED"
}

# --- Scoped test runner ---

@test "run_test_file: runs only the specified test file" {
  local tmpdir=$(mktemp -d)
  cd "$tmpdir"

  TDD_TEST_CMD="echo"
  tdd_run_test_file "$TEST_SESSION" "src/Hero.test.tsx"
  local exit_code=$?
  [ "$exit_code" -eq 0 ]

  # The stdout file should contain just the one file path (from echo)
  local stdout_file="/tmp/tdd-test-stdout-${TEST_SESSION}"
  [ -f "$stdout_file" ]
  grep -q "src/Hero.test.tsx" "$stdout_file"
  # Should NOT contain any other test file
  local line_count
  line_count=$(wc -l < "$stdout_file" | tr -d ' ')
  [ "$line_count" -eq 1 ]

  rm -rf "$tmpdir"
}
