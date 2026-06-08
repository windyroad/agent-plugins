#!/usr/bin/env bats
# Doc-lint guard: architect agent.md must carry an explicit pre-edit /
# proposed-change review-mode carve-out so the agent classifies alignment
# of the PROPOSAL when the calling prompt describes a not-yet-applied
# change, instead of mis-classifying not-yet-applied state as ISSUES FOUND
# (P313 catch-22: gate blocks edits; reviewer wants edits done first).
#
# tdd-review: structural-permitted (justification: P176 — agent behaviour is
# prompt-driven with no skill-invocation harness to exercise the verdict
# behaviourally; ADR-052 Surface 2 structural-justified case, NOT an ADR-005
# Permitted Exception — ADR-052 narrows ADR-005 to exclude prose-doc greps).
# When P176 lands, upgrade to a behavioural test that feeds the agent a
# pre-edit proposal and asserts the PASS verdict.
#
# Cross-reference:
#   P313 (Pre-edit governance-gate catch-22 — pass withheld pending edits)
#   ADR-052 Surface 2 (structural-justified verdict) + P176 (harness gap)
#   @jtbd JTBD-001 (Enforce Governance Without Slowing Down — preserves the
#                   under-60-second review outcome by removing the redundant
#                   re-delegation the catch-22 currently forces)

setup() {
  AGENT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  AGENT_FILE="${AGENT_DIR}/agent.md"
}

@test "agent.md carries a Review Mode section distinguishing pre-edit from post-edit (P313)" {
  run grep -nE "^## Review Mode: Pre-edit / proposed-change vs\. Post-edit / applied" "$AGENT_FILE"
  [ "$status" -eq 0 ]
}

@test "agent.md classifies alignment of the PROPOSAL in pre-edit mode (P313 verbatim core sentence)" {
  run grep -nE "classify alignment of the PROPOSAL itself" "$AGENT_FILE"
  [ "$status" -eq 0 ]
}

@test "agent.md treats not-yet-applied state as the EXPECTED baseline of a pre-edit gate (P313)" {
  run grep -nE "EXPECTED baseline of a pre-edit gate" "$AGENT_FILE"
  [ "$status" -eq 0 ]
}

@test "agent.md explicitly rejects 'edits aren't applied yet' as a valid ISSUES FOUND substance (P313)" {
  run grep -nE "Do NOT treat .edits aren't applied yet" "$AGENT_FILE"
  [ "$status" -eq 0 ]
}

@test "agent.md cites P313 as the catch-22 closure (audit-trail)" {
  run grep -nE "P313" "$AGENT_FILE"
  [ "$status" -eq 0 ]
}
