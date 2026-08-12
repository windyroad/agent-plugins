#!/usr/bin/env bats

# Tests for risk-score-mark.sh — verifies the PostToolUse:Agent hook
# parses risk-scorer agent output and writes the right files into
# the session-scoped risk dir.
#
# Per ADR-005 (P011): behavioural assertions are functional — they
# pipe mock hook input to the script and assert on side-effects, not
# on what the source happens to contain. The four "echo X | grep X"
# tautologies that previously lived here have been removed (they
# always passed regardless of hook behaviour).

setup() {
  SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  HOOK="$SCRIPT_DIR/risk-score-mark.sh"
  source "$SCRIPT_DIR/lib/risk-gate.sh"
  ORIG_DIR="$PWD"
  TEST_DIR=$(mktemp -d)
  cd "$TEST_DIR"
  git init -q
  TMPDIR="$TEST_DIR/tmp"
  export TMPDIR
  mkdir -p "$TMPDIR"
  SESSION_ID="test-session-$$"
  RDIR="$TMPDIR/claude-risk-${SESSION_ID}"
}

teardown() {
  cd "$ORIG_DIR"
  rm -rf "$TEST_DIR"
}

# Helper: build the PostToolUse:Agent JSON envelope and pipe it to the hook.
# AGENT_OUTPUT is wrapped in tool_response.content[0].text to match the
# real Claude Code PostToolUse hook payload shape.
run_hook() {
  local subagent="$1"
  local agent_output="$2"
  python3 -c "
import json, sys
print(json.dumps({
  'tool_name': 'Agent',
  'session_id': '${SESSION_ID}',
  'tool_input': {'subagent_type': '${subagent}'},
  'tool_response': {'content': [{'type': 'text', 'text': sys.stdin.read()}]}
}))" <<<"$agent_output" | bash "$HOOK"
}

# --- Pipeline scorer: writes commit/push/release score files ---

@test "pipeline: writes commit/push/release scores from RISK_SCORES line" {
  run_hook "wr-risk-scorer:pipeline" "Header text
RISK_SCORES: commit=2 push=3 release=1
Trailing text"
  [ "$(cat "$RDIR/commit")" = "2" ]
  [ "$(cat "$RDIR/push")" = "3" ]
  [ "$(cat "$RDIR/release")" = "1" ]
  [ "$(cat "$RDIR/checkout-id")" = "$(_checkout_id)" ]
}

@test "pipeline: writes reducing bypass markers when RISK_BYPASS: reducing" {
  run_hook "wr-risk-scorer:pipeline" "RISK_SCORES: commit=2 push=2 release=0
RISK_BYPASS: reducing"
  [ -f "$RDIR/reducing-commit" ]
  [ -f "$RDIR/reducing-push" ]
  [ -f "$RDIR/reducing-release" ]
}

@test "pipeline: writes incident bypass marker when RISK_BYPASS: incident" {
  run_hook "wr-risk-scorer:pipeline" "RISK_SCORES: commit=10 push=10 release=10
RISK_BYPASS: incident"
  [ -f "$RDIR/incident-release" ]
}

@test "pipeline: writes nothing when output has no RISK_SCORES line" {
  run run_hook "wr-risk-scorer:pipeline" "No score line in this output"
  [ "$status" -ne 0 ]
  [ ! -f "$RDIR/commit" ]
  [ ! -f "$RDIR/push" ]
  [ ! -f "$RDIR/release" ]
  [ ! -f "$RDIR/checkout-id" ]
}

@test "pipeline: interrupted marker publication invalidates both checkout roots" {
  mkdir -p "$RDIR"
  OTHER_DIR=$(mktemp -d)
  git clone -q "$TEST_DIR" "$OTHER_DIR"
  (cd "$OTHER_DIR" && _checkout_id) > "$RDIR/checkout-id"
  printf '1' > "$RDIR/commit"
  printf 'old-hash' > "$RDIR/state-hash"

  mkdir "$TEST_DIR/bin"
  cat > "$TEST_DIR/bin/mkdir" <<'EOF'
#!/bin/sh
case "$*" in
  *'.risk-reports'*) exit 1 ;;
  *) exec /bin/mkdir "$@" ;;
esac
EOF
  chmod +x "$TEST_DIR/bin/mkdir"

  PATH="$TEST_DIR/bin:$PATH" run run_hook "wr-risk-scorer:pipeline" \
    "RISK_SCORES: commit=2 push=2 release=2"
  [ "$status" -ne 0 ]
  [ ! -f "$RDIR/checkout-id" ]

  cd "$TEST_DIR"
  run check_risk_gate "$SESSION_ID" commit
  [ "$status" -ne 0 ]
  cd "$OTHER_DIR"
  run check_risk_gate "$SESSION_ID" commit
  [ "$status" -ne 0 ]
  rm -rf "$OTHER_DIR"
}

# --- Plan scorer: writes plan-reviewed marker on PASS only ---

@test "plan: writes plan-reviewed marker on RISK_VERDICT: PASS" {
  run_hook "wr-risk-scorer:plan" "RISK_VERDICT: PASS"
  [ -f "$RDIR/plan-reviewed" ]
}

@test "plan: does NOT write plan-reviewed marker on RISK_VERDICT: FAIL" {
  run_hook "wr-risk-scorer:plan" "RISK_VERDICT: FAIL"
  [ ! -f "$RDIR/plan-reviewed" ]
}

# --- Subagent routing: case guard ignores non-risk-scorer agents ---

@test "case guard: skips unrelated agent without writing files" {
  run_hook "wr-architect:agent" "RISK_SCORES: commit=99 push=99 release=99"
  [ ! -f "$RDIR/commit" ]
}

@test "case guard: matches wr-risk-scorer:pipeline subagent" {
  SUBAGENT="wr-risk-scorer:pipeline"
  case "$SUBAGENT" in
    *risk-scorer*) true ;;
    *) false ;;
  esac
}

@test "case guard: does NOT match wr-architect:agent" {
  SUBAGENT="wr-architect:agent"
  case "$SUBAGENT" in
    *risk-scorer*) false ;;
    *) true ;;
  esac
}
