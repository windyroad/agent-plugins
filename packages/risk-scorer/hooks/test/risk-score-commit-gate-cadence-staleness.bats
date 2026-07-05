#!/usr/bin/env bats

# P408 / ADR-091 / RFC-043 / STORY-037: the POLICY_STALE branch of
# risk-score-commit-gate.sh derives its staleness threshold from the
# policy's stated review cadence line (`> Reviewed <cadence> ...`)
# instead of a hardcoded 14 days. Vocabulary: weekly=7,
# fortnightly/biweekly=14, monthly=30, quarterly=90, annually/yearly=365;
# fallback 14 when the line is absent or the word unrecognised. The
# cadence regex is case-sensitive and must bind the capital-R
# `Reviewed <word>` line, never the lowercase `Last reviewed: <date>`
# line (ADR-091 machine-read contract).

setup() {
  HOOKS_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  GATE_SCRIPT="$HOOKS_DIR/risk-score-commit-gate.sh"
  TEST_SESSION="bats-test-$$-${BATS_TEST_NUMBER}"
  TMP_REPO="$(mktemp -d)"
  cd "$TMP_REPO"
}

teardown() {
  rm -rf "$TMP_REPO"
  rm -rf "${TMPDIR:-/tmp}/claude-risk-${TEST_SESSION}"
}

# Helper: date N days ago, ISO format.
days_ago() {
  python3 -c "from datetime import date, timedelta; print(date.today() - timedelta(days=int('$1')))"
}

# Helper: write a RISK-POLICY.md reviewed N days ago with an optional
# cadence line supplied verbatim as the second argument.
write_policy() {
  local reviewed_days_ago="$1"
  local cadence_line="${2-}"
  {
    echo "# Risk Policy"
    echo ""
    echo "> Last reviewed: $(days_ago "$reviewed_days_ago")"
    if [ -n "$cadence_line" ]; then
      echo ""
      echo "$cadence_line"
    fi
  } > RISK-POLICY.md
}

# Helper: invoke the gate with a git-commit Bash payload.
invoke_gate() {
  local input
  input=$(python3 -c "
import json, sys
print(json.dumps({
    'tool_name': 'Bash',
    'tool_input': {'command': 'git commit -m \"feat: change\"'},
    'session_id': sys.argv[1]
}))
" "$TEST_SESSION")
  echo "$input" | bash "$GATE_SCRIPT"
}

@test "P408: monthly cadence, reviewed 16 days ago — NOT stale (witnessed case; deny is the score gate, not staleness)" {
  write_policy 16 "> Reviewed monthly and after any significant change to distribution channels."
  run invoke_gate
  # The gate still denies (no risk score for this session) but the reason
  # must NOT be policy staleness.
  [[ "$output" == *"deny"* ]]
  [[ "$output" != *"stale"* ]]
}

@test "P408: no cadence line, reviewed 16 days ago — 14-day fallback still flags stale (behaviour preserved)" {
  write_policy 16
  run invoke_gate
  [[ "$output" == *"stale"* ]]
}

@test "P408: unrecognised cadence word falls back to 14 days" {
  write_policy 16 "> Reviewed sporadically whenever convenient."
  run invoke_gate
  [[ "$output" == *"stale"* ]]
}

@test "P408: regex binds the capital-R cadence line, never the lowercase 'Last reviewed:' date line" {
  # Quarterly cadence, reviewed 20 days ago. If the regex wrongly bound
  # the 'Last reviewed:' line the capture would fail and the 14-day
  # fallback would flag stale at 20 days; correct capital-R binding
  # derives 90 days and passes.
  write_policy 20 "> Reviewed quarterly."
  run invoke_gate
  [[ "$output" == *"deny"* ]]
  [[ "$output" != *"stale"* ]]
}

@test "P408: elapsed monthly cadence denies and the message names the derived threshold and cadence word" {
  write_policy 45 "> Reviewed monthly."
  run invoke_gate
  [[ "$output" == *"stale"* ]]
  [[ "$output" == *"30"* ]]
  [[ "$output" == *"monthly"* ]]
}

@test "P408: weekly cadence tightens the threshold below the default (10 days is stale under weekly)" {
  write_policy 10 "> Reviewed weekly."
  run invoke_gate
  [[ "$output" == *"stale"* ]]
}
