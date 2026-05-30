#!/usr/bin/env bats

# Behavioural tests for architect-mark-reviewed.sh verdict parsing (P181).
# Drives the hook with realistic agent-output payloads and asserts marker
# creation matches the heading-shape contract in
# packages/architect/agents/agent.md "How to Report".
#
# P181 root cause: literal-substring grep `grep -q "ISSUES FOUND"` matches
# anywhere in the response — including prose narrative that mentions the
# verdict string without it being the canonical heading. Anchored heading
# match fixes the false-positive FAIL → silent marker-drop → edit block.

setup() {
  HOOKS_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  HOOK="$HOOKS_DIR/architect-mark-reviewed.sh"
  TEST_SESSION="bats-arch-verdict-$$-${BATS_TEST_NUMBER}"
  REVIEW_MARKER="/tmp/architect-reviewed-${TEST_SESSION}"
  HASH_MARKER="/tmp/architect-reviewed-${TEST_SESSION}.hash"
  PLAN_MARKER="/tmp/architect-plan-reviewed-${TEST_SESSION}"
  rm -f "$REVIEW_MARKER" "$HASH_MARKER" "$PLAN_MARKER"
}

teardown() {
  rm -f "$REVIEW_MARKER" "$HASH_MARKER" "$PLAN_MARKER"
}

# Build a PostToolUse:Agent input JSON with the given agent-output text.
# Uses python3 (already a hard dep of gate-helpers.sh) for safe escaping.
_make_input() {
  local text="$1"
  python3 -c "
import json, sys
text = sys.argv[1]
print(json.dumps({
    'session_id': '$TEST_SESSION',
    'tool_name': 'Agent',
    'tool_input': {'subagent_type': 'wr-architect:agent'},
    'tool_response': {'content': [{'type': 'text', 'text': text}]}
}))
" "$text"
}

# ---------------------------------------------------------------------------
# Sanity: canonical headings classify correctly
# ---------------------------------------------------------------------------

@test "verdict-grep: marker drops on canonical PASS heading" {
  INPUT=$(_make_input "**Architecture Review: PASS**

No conflicts with existing decisions.")
  echo "$INPUT" | "$HOOK"
  [ -f "$REVIEW_MARKER" ]
}

@test "verdict-grep: marker NOT created on canonical ISSUES FOUND heading" {
  INPUT=$(_make_input "**Architecture Review: ISSUES FOUND**

1. [Decision Conflict] — ADR-009 violation.")
  echo "$INPUT" | "$HOOK"
  [ ! -f "$REVIEW_MARKER" ]
}

@test "verdict-grep: marker drops on PASS heading with blockquote prefix" {
  INPUT=$(_make_input "> **Architecture Review: PASS**
> No conflicts.")
  echo "$INPUT" | "$HOOK"
  [ -f "$REVIEW_MARKER" ]
}

@test "verdict-grep: marker NOT created on ISSUES FOUND heading with blockquote prefix" {
  INPUT=$(_make_input "> **Architecture Review: ISSUES FOUND**
> 1. [Conflict] ...")
  echo "$INPUT" | "$HOOK"
  [ ! -f "$REVIEW_MARKER" ]
}

# ---------------------------------------------------------------------------
# P181 bug-fix cases: substring-anywhere false-positive FAIL
# ---------------------------------------------------------------------------

@test "verdict-grep: marker drops when no canonical heading + body mentions 'ISSUES FOUND' inline (P181)" {
  # Agent emits prose without a canonical heading but the narrative discusses
  # the concept of ISSUES FOUND. Current substring grep falsely classifies
  # this as FAIL → no marker. After fix: anchored regex doesn't match → falls
  # through to default branch → marker drops (lockout-avoidance).
  INPUT=$(_make_input "I reviewed the change. The previous review surfaced ISSUES FOUND that have since been addressed; the current proposed change is fine.")
  echo "$INPUT" | "$HOOK"
  [ -f "$REVIEW_MARKER" ]
}

@test "verdict-grep: marker drops on NEEDS DIRECTION heading even if body prose mentions 'ISSUES FOUND' (P181)" {
  # NEEDS DIRECTION is one of three canonical verdicts (agent.md line 137).
  # It currently falls through to the default branch (creates marker for
  # backward-compat lockout-avoidance). The bug: if the body narratively
  # references the ISSUES FOUND verdict shape, substring grep fires FAIL.
  # After fix: neither anchored regex matches → fallback creates marker.
  INPUT=$(_make_input "**Architecture Review: NEEDS DIRECTION**

A decision must be recorded. This differs from an ISSUES FOUND verdict because the option is not pinned.

- Option A — ...
- Option B — ...")
  echo "$INPUT" | "$HOOK"
  [ -f "$REVIEW_MARKER" ]
}

@test "verdict-grep: marker drops when PASS heading present and body also says 'ISSUES FOUND' inline" {
  # PASS check runs first and must win even with substring noise downstream.
  # This works in both old and new code; sanity-anchors the precedence rule.
  INPUT=$(_make_input "**Architecture Review: PASS**

No conflicts. Note: earlier sessions reported ISSUES FOUND on adjacent files but those are out of scope here.")
  echo "$INPUT" | "$HOOK"
  [ -f "$REVIEW_MARKER" ]
}

@test "verdict-grep: marker drops when body just says 'no issues found' in prose" {
  # Verbatim substring "issues found" should not satisfy the anchored
  # ISSUES FOUND regex (which requires the bold heading shape). Old code:
  # grep -q "ISSUES FOUND" is case-sensitive so 'issues found' lowercase
  # doesn't match either — this test pins case-sensitivity behaviour so
  # future regex changes don't accidentally relax it.
  INPUT=$(_make_input "Review complete — no issues found in the diff.")
  echo "$INPUT" | "$HOOK"
  [ -f "$REVIEW_MARKER" ]
}
