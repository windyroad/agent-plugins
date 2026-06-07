#!/usr/bin/env bats
# P192: Risk-reducing/within-appetite bypass markers (`reducing-commit`,
# `reducing-push`, `reducing-release`) must persist across multiple commits/
# pushes/releases within the standard TTL window AS LONG AS the pipeline-state
# hash still matches what was scored — eliminating the per-commit re-mint
# round-trip that drives the 3+-rescores-per-session friction. Drift or TTL
# expiry consumes the marker and forces a fresh `wr-risk-scorer:pipeline`
# rescore. `incident-release` remains single-use (deliberate one-time
# override).
#
# Behavioural contract:
#   (a) reducing-* marker exists + tree hash matches stored state-hash + TTL
#       not expired → gate allows AND marker persists (reusable).
#   (b) reducing-* marker exists + tree hash differs from state-hash → marker
#       consumed, gate falls through to check_risk_gate (which denies on
#       drift or missing score).
#   (c) reducing-* marker exists + TTL expired (relative to marker mtime) →
#       marker consumed, gate falls through.
#   (d) incident-release marker stays single-use (unchanged behaviour) —
#       regression guard.
#
# Tests invoke the gate hooks directly (script + stdin JSON), the way the
# Claude Code hook runtime calls them.

setup() {
  HOOKS_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  COMMIT_GATE="$HOOKS_DIR/risk-score-commit-gate.sh"
  PUSH_GATE="$HOOKS_DIR/git-push-gate.sh"

  TEST_SESSION="bats-p192-$$-${BATS_TEST_NUMBER}"
  RDIR="${TMPDIR:-/tmp}/claude-risk-${TEST_SESSION}"
  rm -rf "$RDIR"
  mkdir -p "$RDIR"

  # Minimal git repo so pipeline-state.sh --hash-inputs produces a stable
  # tree hash (git stash create needs a real repo).
  TMP_REPO="$(mktemp -d)"
  cd "$TMP_REPO"
  git init -q -b main
  git config user.email "test@example.com"
  git config user.name "Test"
  cat > RISK-POLICY.md <<EOF
# Risk Policy

Last reviewed: $(date -u +%Y-%m-%d)

## Risk Appetite

Pipeline gates block when cumulative residual risk exceeds 4.
EOF
  git add RISK-POLICY.md
  git commit -q -m "initial"

  # Default short TTL so we can exercise expiry without slow tests.
  export RISK_TTL=5
}

teardown() {
  rm -rf "$RDIR"
  rm -rf "$TMP_REPO"
  unset RISK_TTL 2>/dev/null || true
}

# Compute the current pipeline-state hash the same way the gate does
_current_hash() {
  bash -c "
    source '$HOOKS_DIR/lib/gate-helpers.sh'
    '$HOOKS_DIR/lib/pipeline-state.sh' --hash-inputs 2>/dev/null | _hashcmd | cut -d' ' -f1
  "
}

# Portable backdate by N seconds
_backdate() {
  local file="$1" seconds="$2"
  local stamp
  stamp=$(date -v-${seconds}S +%Y%m%d%H%M.%S 2>/dev/null \
       || date -d "${seconds} seconds ago" +%Y%m%d%H%M.%S 2>/dev/null)
  touch -t "$stamp" "$file"
}

invoke_commit_gate() {
  local cmd="$1"
  local input
  input=$(python3 -c "
import json, sys
print(json.dumps({
  'tool_name': 'Bash',
  'tool_input': {'command': sys.argv[1]},
  'session_id': sys.argv[2],
}))
" "$cmd" "$TEST_SESSION")
  echo "$input" | bash "$COMMIT_GATE"
}

invoke_push_gate() {
  local cmd="$1"
  local input
  input=$(python3 -c "
import json, sys
print(json.dumps({
  'tool_name': 'Bash',
  'tool_input': {'command': sys.argv[1]},
  'session_id': sys.argv[2],
}))
" "$cmd" "$TEST_SESSION")
  echo "$input" | bash "$PUSH_GATE"
}

# ---------------------------------------------------------------------------
# Commit gate — reducing-commit persistence
# ---------------------------------------------------------------------------

@test "reducing-commit marker persists when tree hash matches stored state-hash" {
  HASH=$(_current_hash)
  echo "$HASH" > "$RDIR/state-hash"
  touch "$RDIR/reducing-commit"

  run invoke_commit_gate 'git commit -m "x"'
  [ "$status" -eq 0 ]
  [[ "$output" != *"deny"* ]]

  # Marker MUST still exist after a successful allow — this is the load-
  # bearing behaviour change.
  [ -f "$RDIR/reducing-commit" ]
}

@test "reducing-commit marker survives back-to-back commits (no rescore round-trip)" {
  HASH=$(_current_hash)
  echo "$HASH" > "$RDIR/state-hash"
  touch "$RDIR/reducing-commit"

  # Three sequential allows — current single-use marker consumes on first,
  # leaving #2 and #3 to fall through to check_risk_gate (which denies on
  # missing score). New persistent-within-TTL contract: all three pass.
  run invoke_commit_gate 'git commit -m "1"'; [ "$status" -eq 0 ]; [[ "$output" != *"deny"* ]]
  run invoke_commit_gate 'git commit -m "2"'; [ "$status" -eq 0 ]; [[ "$output" != *"deny"* ]]
  run invoke_commit_gate 'git commit -m "3"'; [ "$status" -eq 0 ]; [[ "$output" != *"deny"* ]]

  [ -f "$RDIR/reducing-commit" ]
}

@test "reducing-commit marker is consumed when tree hash drifts from stored state-hash" {
  echo "stale-hash-value-from-prior-tree" > "$RDIR/state-hash"
  touch "$RDIR/reducing-commit"

  run invoke_commit_gate 'git commit -m "x"'
  # Marker MUST be consumed when drift detected.
  [ ! -f "$RDIR/reducing-commit" ]
}

@test "reducing-commit marker is consumed when TTL has expired" {
  HASH=$(_current_hash)
  echo "$HASH" > "$RDIR/state-hash"
  touch "$RDIR/reducing-commit"
  _backdate "$RDIR/reducing-commit" 10  # TTL is 5

  run invoke_commit_gate 'git commit -m "x"'
  # TTL-expired marker MUST be consumed and the gate must NOT silently allow
  # purely on marker presence.
  [ ! -f "$RDIR/reducing-commit" ]
}

@test "reducing-commit marker without state-hash file is consumed (no invariance proof)" {
  rm -f "$RDIR/state-hash"
  touch "$RDIR/reducing-commit"

  run invoke_commit_gate 'git commit -m "x"'
  # No way to verify tree-invariance → consume the marker rather than ride it.
  [ ! -f "$RDIR/reducing-commit" ]
}

# ---------------------------------------------------------------------------
# Push gate — reducing-push persistence
# ---------------------------------------------------------------------------

@test "reducing-push marker persists when tree hash matches stored state-hash" {
  HASH=$(_current_hash)
  echo "$HASH" > "$RDIR/state-hash"
  touch "$RDIR/reducing-push"

  run invoke_push_gate 'npm run push:watch'
  [ "$status" -eq 0 ]
  [[ "$output" != *"deny"* ]]

  [ -f "$RDIR/reducing-push" ]
}

@test "reducing-push marker is consumed when tree hash drifts" {
  echo "stale-hash" > "$RDIR/state-hash"
  touch "$RDIR/reducing-push"

  run invoke_push_gate 'npm run push:watch'
  [ ! -f "$RDIR/reducing-push" ]
}

# ---------------------------------------------------------------------------
# Release gate — reducing-release persistence
# ---------------------------------------------------------------------------

@test "reducing-release marker persists when tree hash matches stored state-hash" {
  HASH=$(_current_hash)
  echo "$HASH" > "$RDIR/state-hash"
  touch "$RDIR/reducing-release"

  run invoke_push_gate 'npm run release:watch'
  [ "$status" -eq 0 ]
  [[ "$output" != *"deny"* ]]

  [ -f "$RDIR/reducing-release" ]
}

@test "reducing-release marker is consumed when tree hash drifts" {
  echo "stale-hash" > "$RDIR/state-hash"
  touch "$RDIR/reducing-release"

  run invoke_push_gate 'npm run release:watch'
  [ ! -f "$RDIR/reducing-release" ]
}

# ---------------------------------------------------------------------------
# incident-release — single-use regression guard
# ---------------------------------------------------------------------------

@test "incident-release marker REMAINS single-use (regression guard)" {
  HASH=$(_current_hash)
  echo "$HASH" > "$RDIR/state-hash"
  touch "$RDIR/incident-release"

  run invoke_push_gate 'npm run release:watch'
  [ "$status" -eq 0 ]
  [[ "$output" != *"deny"* ]]

  # incident bypass is a deliberate one-time override — must be consumed
  # even when tree hash matches.
  [ ! -f "$RDIR/incident-release" ]
}
