#!/usr/bin/env bats
# Behavioural tests for packages/voice-tone/hooks/external-comms-mark-reviewed.sh
# under P166 hook-side key derivation (ADR-028 amended 2026-05-16).
#
# Contract: the PostToolUse:Agent hook derives the marker key from
# tool_input.prompt's `SURFACE: <name>` + `<draft>...</draft>` structure
# instead of trusting an agent-emitted EXTERNAL_COMMS_VOICE_TONE_KEY line.
# On PASS, writes external-comms-voice-tone-reviewed-<KEY> at the derived
# key. Backward-compat: if the prompt lacks structure, falls back to the
# agent-emitted KEY line (one release-cycle window per architect direction).

setup() {
  SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  HOOK="$SCRIPT_DIR/external-comms-mark-reviewed.sh"
  ORIG_DIR="$PWD"
  TEST_DIR=$(mktemp -d)
  cd "$TEST_DIR"
  TMPDIR="$TEST_DIR/tmp"
  export TMPDIR
  mkdir -p "$TMPDIR"
  SESSION_ID="test-vt-mark-prompt-$$-${BATS_TEST_NUMBER}"
  RDIR="$TMPDIR/claude-risk-${SESSION_ID}"
}

teardown() {
  cd "$ORIG_DIR"
  rm -rf "$TEST_DIR"
}

# Gate-side reference key — same computation as external-comms-gate.sh line 229.
gate_key() {
  local draft="$1" surface="$2"
  printf '%s\n%s' "$draft" "$surface" | shasum -a 256 | cut -d' ' -f1
}

# Build the PostToolUse:Agent payload and pipe it to the hook.
# - tool_input.prompt carries the structured prompt the orchestrator sent to the agent.
# - tool_response.content[0].text carries the agent's stdout (verdict block).
run_hook() {
  local prompt="$1"
  local agent_output="$2"
  python3 -c "
import json, sys
print(json.dumps({
  'tool_name': 'Agent',
  'session_id': '${SESSION_ID}',
  'tool_input': {'subagent_type': 'wr-voice-tone:external-comms', 'prompt': sys.argv[1]},
  'tool_response': {'content': [{'type': 'text', 'text': sys.argv[2]}]}
}))" "$prompt" "$agent_output" | bash "$HOOK"
}

@test "PASS with structured prompt: marker lands at hook-derived key" {
  DRAFT="we noticed a build failure on Node 20"
  SURFACE="changeset-author"
  PROMPT=$'SURFACE: '"$SURFACE"$'\n<draft>\n'"$DRAFT"$'\n</draft>\nReview against docs/VOICE-AND-TONE.md.'
  AGENT_OUTPUT=$'no voice/tone violation matched\nEXTERNAL_COMMS_VOICE_TONE_VERDICT: PASS'
  run_hook "$PROMPT" "$AGENT_OUTPUT"
  KEY=$(gate_key "$DRAFT" "$SURFACE")
  [ -f "$RDIR/external-comms-voice-tone-reviewed-${KEY}" ]
}

@test "FAIL with structured prompt: no marker written" {
  DRAFT="happy to help further on this 2-year-old issue"
  SURFACE="gh-issue-comment"
  PROMPT=$'SURFACE: '"$SURFACE"$'\n<draft>\n'"$DRAFT"$'\n</draft>'
  AGENT_OUTPUT=$'EXTERNAL_COMMS_VOICE_TONE_VERDICT: FAIL\nEXTERNAL_COMMS_VOICE_TONE_REASON: banned closer'
  run_hook "$PROMPT" "$AGENT_OUTPUT"
  KEY=$(gate_key "$DRAFT" "$SURFACE")
  [ ! -f "$RDIR/external-comms-voice-tone-reviewed-${KEY}" ]
}

@test "PASS with structured prompt AND agent-emitted KEY: hook-derived key wins" {
  DRAFT="hook-derived path text"
  SURFACE="gh-pr-create"
  PROMPT=$'SURFACE: '"$SURFACE"$'\n<draft>\n'"$DRAFT"$'\n</draft>'
  # Agent emits a different (wrong) key — hook must ignore it in favour of derived key.
  BOGUS_KEY="0000000000000000000000000000000000000000000000000000000000000000"
  AGENT_OUTPUT=$'EXTERNAL_COMMS_VOICE_TONE_VERDICT: PASS\nEXTERNAL_COMMS_VOICE_TONE_KEY: '"$BOGUS_KEY"
  run_hook "$PROMPT" "$AGENT_OUTPUT"
  DERIVED_KEY=$(gate_key "$DRAFT" "$SURFACE")
  [ -f "$RDIR/external-comms-voice-tone-reviewed-${DERIVED_KEY}" ]
  [ ! -f "$RDIR/external-comms-voice-tone-reviewed-${BOGUS_KEY}" ]
}

@test "backward-compat: PASS with no structured prompt but agent-emitted KEY lands marker" {
  # Cached old SKILL.md still tells the agent to emit the KEY; hook honours it.
  LEGACY_KEY="abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789"
  PROMPT="please review this draft (legacy unstructured prompt)"
  AGENT_OUTPUT=$'EXTERNAL_COMMS_VOICE_TONE_VERDICT: PASS\nEXTERNAL_COMMS_VOICE_TONE_KEY: '"$LEGACY_KEY"
  run_hook "$PROMPT" "$AGENT_OUTPUT"
  [ -f "$RDIR/external-comms-voice-tone-reviewed-${LEGACY_KEY}" ]
}

@test "no structured prompt and no agent KEY: no marker written" {
  PROMPT="legacy prompt"
  AGENT_OUTPUT=$'EXTERNAL_COMMS_VOICE_TONE_VERDICT: PASS'
  run_hook "$PROMPT" "$AGENT_OUTPUT"
  # Nothing to key on — no marker at any path under RDIR.
  found=$(ls "$RDIR" 2>/dev/null | wc -l | tr -d ' ')
  [ "$found" -eq 0 ]
}

@test "ignores unrelated subagent types" {
  PROMPT=$'SURFACE: gh-issue-create\n<draft>\nbody\n</draft>'
  AGENT_OUTPUT=$'EXTERNAL_COMMS_VOICE_TONE_VERDICT: PASS'
  # Swap the subagent type in the input to an unrelated one.
  python3 -c "
import json, sys
print(json.dumps({
  'tool_name': 'Agent',
  'session_id': '${SESSION_ID}',
  'tool_input': {'subagent_type': 'wr-architect:agent', 'prompt': sys.argv[1]},
  'tool_response': {'content': [{'type': 'text', 'text': sys.argv[2]}]}
}))" "$PROMPT" "$AGENT_OUTPUT" | bash "$HOOK"
  found=$(ls "$RDIR" 2>/dev/null | wc -l | tr -d ' ')
  [ "$found" -eq 0 ]
}
