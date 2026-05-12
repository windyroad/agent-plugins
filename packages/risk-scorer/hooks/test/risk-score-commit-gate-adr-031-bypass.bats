#!/usr/bin/env bats

# P170 / RFC-002 / ADR-031 T11: risk-score-commit-gate.sh recognises
# the `RISK_BYPASS: adr-031-migration` self-attestation marker in the
# git commit command's message arguments. Migration commits emitted by
# `migrate_problems_to_per_state_layout` carry this marker in their
# body so adopter auto-migration commits skip the full risk-score
# overhead while preserving the audit trail (per ADR-031 § Open
# Execution-time Questions resolution Q3 lean (b)).

setup() {
  HOOKS_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  GATE_SCRIPT="$HOOKS_DIR/risk-score-commit-gate.sh"
  TEST_SESSION="bats-test-$$-${BATS_TEST_NUMBER}"

  # Run inside a temp work tree so the gate's RISK-POLICY.md presence
  # check has something to bind to. The migration test fixture (T10)
  # creates a real adopter repo; here we just need a minimal stub.
  TMP_REPO="$(mktemp -d)"
  cd "$TMP_REPO"
  cat > RISK-POLICY.md <<EOF
# Risk Policy

Last reviewed: $(date -u +%Y-%m-%d)
EOF
}

teardown() {
  rm -rf "$TMP_REPO"
  rm -rf "${TMPDIR:-/tmp}/claude-risk-${TEST_SESSION}"
}

# Helper: invoke the gate with a Bash tool_input json + given command.
# Returns 0 if gate allows (exits 0 with no JSON deny), non-zero on deny.
invoke_gate() {
  local command="$1"
  local input
  input=$(python3 -c "
import json, sys
print(json.dumps({
    'tool_name': 'Bash',
    'tool_input': {'command': sys.argv[1]},
    'session_id': sys.argv[2]
}))
" "$command" "$TEST_SESSION")
  echo "$input" | bash "$GATE_SCRIPT"
}

@test "T11: commit with RISK_BYPASS: adr-031-migration marker bypasses the gate" {
  local cmd='git commit -m "docs(problems): auto-migrate" -m "RISK_BYPASS: adr-031-migration"'
  run invoke_gate "$cmd"
  [ "$status" -eq 0 ]
  # Gate should emit NO deny JSON when bypassed (silent allow).
  [[ "$output" != *"permissionDecision"* ]] || [[ "$output" != *"deny"* ]]
}

@test "T11: commit message body containing RISK_BYPASS marker (multi-paragraph -m sequence) bypasses" {
  local cmd='git commit -m "docs(problems): auto-migrate to per-state subdirectory layout (ADR-031)" -m "See: docs/decisions/031-problem-ticket-directory-layout.accepted.md" -m "RISK_BYPASS: adr-031-migration"'
  run invoke_gate "$cmd"
  [ "$status" -eq 0 ]
  [[ "$output" != *"permissionDecision"* ]] || [[ "$output" != *"deny"* ]]
}

@test "T11: normal commit without RISK_BYPASS marker still gated (no score = deny)" {
  local cmd='git commit -m "feat: normal commit"'
  run invoke_gate "$cmd"
  # Either exits with deny JSON output OR exits non-zero — both indicate the
  # gate didn't silently allow. We assert deny JSON appears in the output.
  [[ "$output" == *"deny"* ]]
}

@test "T11: heredoc-style git commit -m with embedded RISK_BYPASS marker bypasses" {
  # Heredoc shape used by the migration routine + manual workflows;
  # marker must be detected regardless of how the message reaches the
  # command string.
  local cmd=$'git commit -m "$(cat <<\'EOF\'\ndocs(problems): auto-migrate\n\nRISK_BYPASS: adr-031-migration\nEOF\n)"'
  run invoke_gate "$cmd"
  [ "$status" -eq 0 ]
  [[ "$output" != *"permissionDecision"* ]] || [[ "$output" != *"deny"* ]]
}

@test "T11: marker is case-sensitive (adr-031-MIGRATION not recognised — security guard)" {
  local cmd='git commit -m "RISK_BYPASS: adr-031-MIGRATION"'
  run invoke_gate "$cmd"
  [[ "$output" == *"deny"* ]]
}

@test "T11: unrelated RISK_BYPASS token (e.g. reducing) does NOT match adr-031-migration path" {
  # `reducing` is the existing risk-score-mark.sh marker for risk-reducing
  # scoring runs — different mechanism (filesystem marker via PostToolUse
  # agent return), not commit-message detection. The commit-gate should
  # NOT treat a `RISK_BYPASS: reducing` line in the COMMIT MESSAGE as a
  # bypass — only `adr-031-migration` (and any future commit-message
  # markers added explicitly).
  local cmd='git commit -m "RISK_BYPASS: reducing"'
  run invoke_gate "$cmd"
  [[ "$output" == *"deny"* ]]
}
