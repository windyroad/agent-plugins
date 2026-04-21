#!/bin/bash
# Shared session-announcement marker helpers (P095 / ADR-038).
#
# Used by UserPromptSubmit hooks to gate verbose MANDATORY instruction
# prose behind a once-per-session check. First prompt of a session emits
# the full block AND calls mark_announced; subsequent prompts see the
# marker via has_announced and emit only a terse reminder.
#
# Why no TTL or drift check (unlike review-gate.sh): announcement is
# bookkeeping for prose verbosity, not enforcement. PreToolUse gates
# still block unauthorised edits regardless of announcement state; the
# delegated agent re-reads policy when it runs. Extending the marker's
# lifetime across policy changes mid-session is safe — the gate, not
# the announcement, is load-bearing.
#
# Marker path convention: /tmp/${SYSTEM}-announced-${SESSION_ID}
# (mirrors the /tmp/${SYSTEM}-reviewed-${SESSION_ID} convention from
# style-guide/voice-tone/risk-scorer review-gate.sh; the -announced-
# suffix distinguishes announcement markers from clearance markers).
#
# Empty SESSION_ID fallback: has_announced returns 1 (not announced,
# full block emits) and mark_announced is a no-op (no file written).
# This covers manual hook invocation, test harnesses, and any rare
# case where Claude Code does not pass a session_id on stdin.

# Returns 0 if the hook for SYSTEM has already announced in SESSION_ID,
# 1 otherwise. Empty SESSION_ID => returns 1 (never announced).
#
# Usage: has_announced "architect" "$SESSION_ID"
has_announced() {
  local SYSTEM="$1"
  local SESSION_ID="$2"
  [ -n "$SESSION_ID" ] || return 1
  [ -f "/tmp/${SYSTEM}-announced-${SESSION_ID}" ]
}

# Writes the announcement marker for SYSTEM in SESSION_ID. Empty
# SESSION_ID => no-op. Safe to call more than once per session.
#
# Usage: mark_announced "architect" "$SESSION_ID"
mark_announced() {
  local SYSTEM="$1"
  local SESSION_ID="$2"
  [ -n "$SESSION_ID" ] || return 0
  : > "/tmp/${SYSTEM}-announced-${SESSION_ID}"
}
