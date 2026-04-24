#!/usr/bin/env bats
# Tests for .claude/hooks/lib/risk-gate.sh

setup() {
  HOOKS_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  source "$HOOKS_DIR/lib/gate-helpers.sh"
  source "$HOOKS_DIR/lib/risk-gate.sh"

  TEST_SESSION="bats-test-$$-${BATS_TEST_NUMBER}"
  RDIR=$(_risk_dir "$TEST_SESSION")
  SCORE_FILE="${RDIR}/commit"
  HASH_FILE="${RDIR}/state-hash"

  export RISK_TTL=5
  rm -f "$SCORE_FILE" "$HASH_FILE"
}

teardown() {
  rm -rf "${TMPDIR:-/tmp}/claude-risk-${TEST_SESSION}"
}

# Helper: call check_risk_gate directly (not via run) so RISK_GATE_REASON is visible
assert_gate_denies() {
  local session="$1" action="$2" expected_reason="$3"
  RISK_GATE_REASON=""
  if check_risk_gate "$session" "$action"; then
    echo "Expected gate to deny but it allowed"
    return 1
  fi
  if [[ "$RISK_GATE_REASON" != *"$expected_reason"* ]]; then
    echo "Expected reason to contain '$expected_reason' but got: $RISK_GATE_REASON"
    return 1
  fi
}

assert_gate_allows() {
  local session="$1" action="$2"
  if ! check_risk_gate "$session" "$action"; then
    echo "Expected gate to allow but it denied: $RISK_GATE_REASON"
    return 1
  fi
}

@test "missing score file denies" {
  assert_gate_denies "$TEST_SESSION" "commit" "No commit risk score found"
}

@test "score file with PENDING denies (non-numeric)" {
  printf 'PENDING' > "$SCORE_FILE"
  assert_gate_denies "$TEST_SESSION" "commit" "invalid value"
}

@test "score 4 allows (below threshold)" {
  printf '4' > "$SCORE_FILE"
  assert_gate_allows "$TEST_SESSION" "commit"
}

@test "score 5 denies (at threshold)" {
  printf '5' > "$SCORE_FILE"
  assert_gate_denies "$TEST_SESSION" "commit" "5/25"
}

@test "score 8 denies (above threshold)" {
  printf '8' > "$SCORE_FILE"
  assert_gate_denies "$TEST_SESSION" "commit" "8/25"
}

@test "score 1 allows (very low)" {
  printf '1' > "$SCORE_FILE"
  assert_gate_allows "$TEST_SESSION" "commit"
}

@test "expired score file denies" {
  printf '3' > "$SCORE_FILE"
  # Backdate mtime by 10 seconds (TTL is 5)
  touch -t "$(date -v-10S +%Y%m%d%H%M.%S 2>/dev/null || date -d '10 seconds ago' +%Y%m%d%H%M.%S 2>/dev/null)" "$SCORE_FILE"
  assert_gate_denies "$TEST_SESSION" "commit" "expired"
}

@test "fresh score file allows" {
  printf '3' > "$SCORE_FILE"
  touch "$SCORE_FILE"
  assert_gate_allows "$TEST_SESSION" "commit"
}

@test "drift detection: hash mismatch denies" {
  printf '3' > "$SCORE_FILE"
  touch "$SCORE_FILE"
  echo "oldhash123" > "$HASH_FILE"
  assert_gate_denies "$TEST_SESSION" "commit" "drift"
}

@test "no hash file skips drift check (backwards compat)" {
  printf '3' > "$SCORE_FILE"
  touch "$SCORE_FILE"
  rm -f "$HASH_FILE"
  assert_gate_allows "$TEST_SESSION" "commit"
}

@test "risk_gate_deny outputs valid JSON" {
  run risk_gate_deny "Test reason"
  [ "$status" -eq 0 ]
  echo "$output" | python3 -c "import sys, json; json.load(sys.stdin)" 2>/dev/null
  [[ "$output" == *"permissionDecision"* ]]
  [[ "$output" == *"deny"* ]]
  [[ "$output" == *"Test reason"* ]]
}

# ---------------------------------------------------------------------------
# Three-band TTL policy (P090)
# Band A: age < TTL/2 → pass silently, no slide
# Band B: TTL/2 <= age < TTL → consult state-hash; if invariant, pass + slide
#         the marker forward (touch score file) bounded by 2*TTL hard cap
#         from the scorer-run birth time (<action>-born); if drifted, halt
# Band C: age >= TTL → halt with existing "expired" message
# ---------------------------------------------------------------------------

# Helper: backdate file mtime by N seconds (portable between macOS and Linux)
_backdate() {
  local file="$1" seconds="$2"
  local stamp
  stamp=$(date -v-${seconds}S +%Y%m%d%H%M.%S 2>/dev/null \
       || date -d "${seconds} seconds ago" +%Y%m%d%H%M.%S 2>/dev/null)
  touch -t "$stamp" "$file"
}

# Helper: write a matching state-hash for the current working tree
_write_matching_hash() {
  local target="$1"
  local hash
  hash=$("$HOOKS_DIR/lib/pipeline-state.sh" --hash-inputs 2>/dev/null | _hashcmd | cut -d' ' -f1)
  echo "$hash" > "$target"
}

@test "Band A (age < TTL/2): passes, does NOT slide the marker" {
  printf '3' > "$SCORE_FILE"
  touch "$SCORE_FILE"
  rm -f "$HASH_FILE"
  BEFORE_MTIME=$(_mtime "$SCORE_FILE")
  sleep 1
  assert_gate_allows "$TEST_SESSION" "commit"
  AFTER_MTIME=$(_mtime "$SCORE_FILE")
  [ "$BEFORE_MTIME" = "$AFTER_MTIME" ]
}

@test "Band B (TTL/2 <= age < TTL) with hash invariant: passes AND slides marker forward" {
  printf '3' > "$SCORE_FILE"
  _backdate "$SCORE_FILE" 3
  _write_matching_hash "$HASH_FILE"
  touch "${SCORE_FILE}-born"
  BEFORE_MTIME=$(_mtime "$SCORE_FILE")
  assert_gate_allows "$TEST_SESSION" "commit"
  AFTER_MTIME=$(_mtime "$SCORE_FILE")
  [ "$AFTER_MTIME" -gt "$BEFORE_MTIME" ]
}

@test "Band B with no hash file: passes but does NOT slide (no invariance proof)" {
  printf '3' > "$SCORE_FILE"
  _backdate "$SCORE_FILE" 3
  rm -f "$HASH_FILE"
  BEFORE_MTIME=$(_mtime "$SCORE_FILE")
  sleep 1
  assert_gate_allows "$TEST_SESSION" "commit"
  AFTER_MTIME=$(_mtime "$SCORE_FILE")
  [ "$BEFORE_MTIME" = "$AFTER_MTIME" ]
}

@test "Band B with hash mismatch: denies with drift (no slide)" {
  printf '3' > "$SCORE_FILE"
  _backdate "$SCORE_FILE" 3
  echo "staleold" > "$HASH_FILE"
  touch "${SCORE_FILE}-born"
  BEFORE_MTIME=$(_mtime "$SCORE_FILE")
  assert_gate_denies "$TEST_SESSION" "commit" "drift"
  AFTER_MTIME=$(_mtime "$SCORE_FILE")
  [ "$BEFORE_MTIME" = "$AFTER_MTIME" ]
}

@test "Band B with hard-cap exceeded (born-age >= 2*TTL): denies even if hash invariant" {
  printf '3' > "$SCORE_FILE"
  _backdate "$SCORE_FILE" 3
  _write_matching_hash "$HASH_FILE"
  touch "${SCORE_FILE}-born"
  _backdate "${SCORE_FILE}-born" 12
  assert_gate_denies "$TEST_SESSION" "commit" "expired"
}

@test "Band C (age >= TTL): denies regardless of hash invariance" {
  printf '3' > "$SCORE_FILE"
  _backdate "$SCORE_FILE" 10
  _write_matching_hash "$HASH_FILE"
  touch "${SCORE_FILE}-born"
  assert_gate_denies "$TEST_SESSION" "commit" "expired"
}

@test "Band B denial exports RISK_GATE_CATEGORY=drift on hash mismatch" {
  printf '3' > "$SCORE_FILE"
  _backdate "$SCORE_FILE" 3
  echo "staleold" > "$HASH_FILE"
  RISK_GATE_CATEGORY=""
  ! check_risk_gate "$TEST_SESSION" "commit"
  [ "$RISK_GATE_CATEGORY" = "drift" ]
}

@test "Band C denial exports RISK_GATE_CATEGORY=expired" {
  printf '3' > "$SCORE_FILE"
  _backdate "$SCORE_FILE" 10
  RISK_GATE_CATEGORY=""
  ! check_risk_gate "$TEST_SESSION" "commit"
  [ "$RISK_GATE_CATEGORY" = "expired" ]
}

@test "Threshold denial exports RISK_GATE_CATEGORY=threshold and RISK_GATE_SCORE" {
  printf '7' > "$SCORE_FILE"
  touch "$SCORE_FILE"
  RISK_GATE_CATEGORY=""
  RISK_GATE_SCORE=""
  ! check_risk_gate "$TEST_SESSION" "commit"
  [ "$RISK_GATE_CATEGORY" = "threshold" ]
  [ "$RISK_GATE_SCORE" = "7" ]
}
