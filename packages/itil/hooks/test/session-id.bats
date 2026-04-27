#!/usr/bin/env bats

# P124: session-id.sh helper must canonicalise per-session UUID discovery
# for agent-side code paths (e.g. /wr-itil:manage-problem Step 2 substep 7
# marker write) that today fall back to the brittle ${CLAUDE_SESSION_ID:-default}
# pattern when the env var is not exported in the agent's process.
#
# Behavioural contract:
#   1. CLAUDE_SESSION_ID exported -> echo it (env-var fast path).
#   2. CLAUDE_SESSION_ID absent + an /tmp/<system>-announced-<UUID> marker
#      present -> echo the UUID parsed from the marker filename.
#   3. CLAUDE_SESSION_ID absent + no markers anywhere -> echo nothing,
#      exit non-zero (so callers can detect "could not discover").
#   4. Multiple announce markers across systems -> deterministic selection
#      (architect first, then jtbd, then tdd, then itil-assistant-gate,
#      then itil-correction-detect, then style-guide, then voice-tone)
#      so the discovery is reproducible across invocations.
#
# Per feedback_behavioural_tests.md (P081): tests assert the helper's
# emitted output and exit code, not the source content of the helper.
# The marker-system selection order is asserted by constructing only the
# higher-priority marker and checking the helper picks it.

setup() {
  SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  HELPER="$SCRIPT_DIR/lib/session-id.sh"
  # Use a sandbox /tmp so we never leak across real session markers.
  SANDBOX_TMP=$(mktemp -d)
  # session-id.sh reads from /tmp by default; SESSION_MARKER_DIR
  # overrides that for sandboxed bats runs without touching real
  # session state in /tmp.
  export SESSION_MARKER_DIR="$SANDBOX_TMP"
  unset CLAUDE_SESSION_ID
}

teardown() {
  rm -rf "$SANDBOX_TMP"
  unset SESSION_MARKER_DIR
  unset CLAUDE_SESSION_ID
}

# Helper: source the helper and emit the discovered SID + exit code.
discover() {
  bash -c "source '$HELPER'; get_current_session_id; echo \"EXIT:\$?\""
}

# Helper: write an announce marker with a known UUID under SESSION_MARKER_DIR.
mark_announced() {
  local system="$1"
  local uuid="$2"
  : > "$SESSION_MARKER_DIR/${system}-announced-${uuid}"
}

# --- Behavioural contract: env-var fast path ---

@test "env-var present -> returns the env-var value verbatim" {
  expected_uuid="11111111-1111-1111-1111-111111111111"
  output=$(CLAUDE_SESSION_ID="$expected_uuid" bash -c "source '$HELPER'; get_current_session_id; echo \"EXIT:\$?\"")
  [[ "$output" == *"$expected_uuid"* ]]
  [[ "$output" == *"EXIT:0"* ]]
}

@test "env-var present -> ignores any markers (no scrape)" {
  expected_uuid="22222222-2222-2222-2222-222222222222"
  decoy_uuid="33333333-3333-3333-3333-333333333333"
  mark_announced "architect" "$decoy_uuid"
  output=$(CLAUDE_SESSION_ID="$expected_uuid" bash -c "source '$HELPER'; get_current_session_id; echo \"EXIT:\$?\"")
  [[ "$output" == *"$expected_uuid"* ]]
  [[ "$output" != *"$decoy_uuid"* ]]
}

# --- Behavioural contract: marker-scrape fallback ---

@test "env-var absent + architect-announced marker present -> returns marker UUID" {
  expected_uuid="44444444-4444-4444-4444-444444444444"
  mark_announced "architect" "$expected_uuid"
  output=$(discover)
  [[ "$output" == *"$expected_uuid"* ]]
  [[ "$output" == *"EXIT:0"* ]]
}

@test "env-var absent + only jtbd-announced marker present -> returns marker UUID (fallback chain works)" {
  expected_uuid="55555555-5555-5555-5555-555555555555"
  mark_announced "jtbd" "$expected_uuid"
  output=$(discover)
  [[ "$output" == *"$expected_uuid"* ]]
  [[ "$output" == *"EXIT:0"* ]]
}

@test "env-var absent + no markers anywhere -> empty output, non-zero exit" {
  output=$(discover)
  # Output should be just "EXIT:<non-zero>" with no UUID before it.
  [[ "$output" =~ ^EXIT:[1-9] ]]
}

@test "deterministic priority: architect-announced beats jtbd-announced when both present" {
  architect_uuid="aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
  jtbd_uuid="bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb"
  mark_announced "jtbd" "$jtbd_uuid"
  # Sleep so jtbd marker has older mtime — proves selection is by
  # marker-system priority, not by mtime (the architect-flagged
  # mtime fragility from session 2026-04-26 review).
  sleep 1
  mark_announced "architect" "$architect_uuid"
  output=$(discover)
  [[ "$output" == *"$architect_uuid"* ]]
  [[ "$output" != *"$jtbd_uuid"* ]]
}

# --- Behavioural contract: shell portability (P124 Phase 2) ---
#
# The helper is sourced by `/wr-itil:manage-problem` Step 2 substep 7 from
# whichever shell the agent runs Bash tool calls under. On macOS that is
# zsh by default; the Phase 1 implementation used `shopt -s nullglob` (a
# bash builtin), which under zsh errors with `shopt: command not found`
# and lets the subshell glob expression fall through to a literal
# unmatched-pattern string. The helper then returned a stale or wrong
# UUID — defeating its stated guarantee. Citations: P124 ticket
# "Regression Evidence (2026-04-27)" — main-turn P130 capture, line 119:
# `get_current_session_id:33: command not found: shopt`.
#
# This test asserts the helper works identically under zsh as under bash:
# same UUID returned, exit 0, no `shopt: command not found` error on
# stderr.

@test "zsh portability: helper returns the same UUID under zsh -c as under bash -c" {
  if ! command -v zsh >/dev/null 2>&1; then
    skip "zsh not available"
  fi
  expected_uuid="cccccccc-cccc-cccc-cccc-cccccccccccc"
  mark_announced "architect" "$expected_uuid"
  zsh_run=$(SESSION_MARKER_DIR="$SANDBOX_TMP" zsh -c "source '$HELPER'; get_current_session_id; echo \"EXIT:\$?\"" 2>&1)
  [[ "$zsh_run" == *"$expected_uuid"* ]]
  [[ "$zsh_run" == *"EXIT:0"* ]]
  [[ "$zsh_run" != *"shopt: command not found"* ]]
  [[ "$zsh_run" != *"command not found: shopt"* ]]
}
