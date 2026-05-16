#!/usr/bin/env bats
# Behavioural tests for risk-score-mark.sh external-comms branch under
# P166 hook-side key derivation (ADR-028 amended 2026-05-16).
#
# Contract: the PostToolUse:Agent hook derives the marker key from
# tool_input.prompt's `SURFACE: <name>` + `<draft>...</draft>` structure
# instead of trusting an agent-emitted EXTERNAL_COMMS_RISK_KEY line.
# On PASS, writes external-comms-risk-reviewed-<KEY> at the derived key.
# Backward-compat: falls back to agent-emitted KEY when prompt has no
# structure (one release-cycle window).

setup() {
  SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  HOOK="$SCRIPT_DIR/risk-score-mark.sh"
  ORIG_DIR="$PWD"
  TEST_DIR=$(mktemp -d)
  cd "$TEST_DIR"
  TMPDIR="$TEST_DIR/tmp"
  export TMPDIR
  mkdir -p "$TMPDIR"
  SESSION_ID="test-rs-mark-extcomms-prompt-$$-${BATS_TEST_NUMBER}"
  RDIR="$TMPDIR/claude-risk-${SESSION_ID}"
}

teardown() {
  cd "$ORIG_DIR"
  rm -rf "$TEST_DIR"
}

gate_key() {
  local draft="$1" surface="$2"
  printf '%s\n%s' "$draft" "$surface" | shasum -a 256 | cut -d' ' -f1
}

run_hook() {
  local prompt="$1"
  local agent_output="$2"
  python3 -c "
import json, sys
print(json.dumps({
  'tool_name': 'Agent',
  'session_id': '${SESSION_ID}',
  'tool_input': {'subagent_type': 'wr-risk-scorer:external-comms', 'prompt': sys.argv[1]},
  'tool_response': {'content': [{'type': 'text', 'text': sys.argv[2]}]}
}))" "$prompt" "$agent_output" | bash "$HOOK"
}

@test "external-comms PASS with structured prompt: marker lands at hook-derived key" {
  DRAFT="we observed a leaked secret pattern in the changeset"
  SURFACE="changeset-author"
  PROMPT=$'SURFACE: '"$SURFACE"$'\n<draft>\n'"$DRAFT"$'\n</draft>\nReview against RISK-POLICY.md.'
  AGENT_OUTPUT=$'no Confidential Information class matched\nEXTERNAL_COMMS_RISK_VERDICT: PASS'
  run_hook "$PROMPT" "$AGENT_OUTPUT"
  KEY=$(gate_key "$DRAFT" "$SURFACE")
  [ -f "$RDIR/external-comms-risk-reviewed-${KEY}" ]
}

@test "external-comms FAIL with structured prompt: no marker" {
  DRAFT="client Acme Corp is hitting this"
  SURFACE="gh-issue-create"
  PROMPT=$'SURFACE: '"$SURFACE"$'\n<draft>\n'"$DRAFT"$'\n</draft>'
  AGENT_OUTPUT=$'EXTERNAL_COMMS_RISK_VERDICT: FAIL\nEXTERNAL_COMMS_RISK_REASON: Client names class — "Acme Corp"'
  run_hook "$PROMPT" "$AGENT_OUTPUT"
  KEY=$(gate_key "$DRAFT" "$SURFACE")
  [ ! -f "$RDIR/external-comms-risk-reviewed-${KEY}" ]
}

@test "external-comms PASS with structured prompt AND agent-emitted KEY: hook-derived key wins" {
  DRAFT="hook-derived wins"
  SURFACE="gh-pr-comment"
  PROMPT=$'SURFACE: '"$SURFACE"$'\n<draft>\n'"$DRAFT"$'\n</draft>'
  BOGUS_KEY="0000000000000000000000000000000000000000000000000000000000000000"
  AGENT_OUTPUT=$'EXTERNAL_COMMS_RISK_VERDICT: PASS\nEXTERNAL_COMMS_RISK_KEY: '"$BOGUS_KEY"
  run_hook "$PROMPT" "$AGENT_OUTPUT"
  DERIVED_KEY=$(gate_key "$DRAFT" "$SURFACE")
  [ -f "$RDIR/external-comms-risk-reviewed-${DERIVED_KEY}" ]
  [ ! -f "$RDIR/external-comms-risk-reviewed-${BOGUS_KEY}" ]
}

@test "external-comms backward-compat: PASS with no structured prompt but agent KEY" {
  LEGACY_KEY="fedcba9876543210fedcba9876543210fedcba9876543210fedcba9876543210"
  PROMPT="legacy unstructured prompt"
  AGENT_OUTPUT=$'EXTERNAL_COMMS_RISK_VERDICT: PASS\nEXTERNAL_COMMS_RISK_KEY: '"$LEGACY_KEY"
  run_hook "$PROMPT" "$AGENT_OUTPUT"
  [ -f "$RDIR/external-comms-risk-reviewed-${LEGACY_KEY}" ]
}

@test "external-comms no structured prompt and no agent KEY: no marker" {
  PROMPT="legacy"
  AGENT_OUTPUT=$'EXTERNAL_COMMS_RISK_VERDICT: PASS'
  run_hook "$PROMPT" "$AGENT_OUTPUT"
  ext_markers=$(find "$RDIR" -maxdepth 1 -name 'external-comms-risk-reviewed-*' 2>/dev/null | wc -l | tr -d ' ')
  [ "$ext_markers" -eq 0 ]
}
