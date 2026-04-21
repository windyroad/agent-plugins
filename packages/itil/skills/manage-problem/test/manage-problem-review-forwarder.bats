#!/usr/bin/env bats
# Contract assertions for manage-problem's `review` subcommand forwarder (P071 split slice 2).
#
# Per ADR-010 amended (Skill Granularity section) + P071 phased plan:
# `/wr-itil:manage-problem review` delegates to the new
# `/wr-itil:review-problems` skill via a thin-router forwarder. Original
# skill carries `deprecated-arguments: true` frontmatter (asserted in
# the list-forwarder bats); this file asserts the review-forwarder-specific
# contract.
#
# Structural assertion — Permitted Exception to the source-grep ban
# (ADR-005 / P011 / ADR-037 contract-assertion pattern).
#
# @problem P071
# @jtbd JTBD-001 (enforce governance without slowing down)
# @jtbd JTBD-101 (extend the suite with clear patterns)
#
# Cross-reference:
#   P071: docs/problems/071-argument-based-skill-subcommands-are-not-discoverable.open.md
#   ADR-010 amended — split naming + forwarder contract + deprecated-arguments flag
#   ADR-013 Rule 1 — structured user interaction (forwarder emits systemMessage, not AskUserQuestion)
#   ADR-037 — contract-assertion bats pattern

setup() {
  SKILL_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  SKILL_FILE="${SKILL_DIR}/SKILL.md"
}

@test "manage-problem Step 1 forwards 'review' argument to /wr-itil:review-problems (P071)" {
  # The forwarder names the target skill explicitly so the router is legible
  # at the contract level. ADR-010's canonical shape: "invokes the new
  # named skill via the Skill tool, not via re-prompting the user".
  run grep -inE "/wr-itil:review-problems" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "manage-problem Step 1 emits the canonical review deprecation notice (ADR-010 amended)" {
  # ADR-010's canonical deprecation-notice template:
  # "/wr-<plugin>:<old> <arg> is deprecated; use /wr-<plugin>:<new>
  #  directly. This forwarder will be removed in <plugin>'s next major
  #  version."
  # The notice MUST be emitted as a systemMessage (not AskUserQuestion)
  # because deprecation is informational, not decisional (ADR-013 Rule 1
  # structured-interaction scope). The review-forwarder notice is
  # distinct from the list-forwarder notice; both must co-exist verbatim.
  run grep -inE "is deprecated.*use /wr-itil:review-problems|deprecated.*review-problems|removed in .* next major version" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "manage-problem Step 1 review-forwarder does not re-implement the review logic (P071 regression guard)" {
  # The forwarder must not duplicate the review logic — it must delegate.
  # Per ADR-010: "thin-router forwarder re-invokes the new named skill
  # via the Skill tool". If the forwarder grows its own re-scoring or
  # README-refresh logic, the deprecation window will harden into a
  # permanent fork. Guard against this by asserting the forwarder block
  # mentions "delegate" or "Skill tool" language near the
  # review-problems reference.
  run grep -inE "delegate.*review-problems|Skill tool.*review-problems|review-problems.*Skill tool" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "manage-problem review-forwarder Step 1 parser no longer runs review logic inline (P071 slice 2)" {
  # Slice 2's defining behaviour: Step 1's `review` branch must
  # delegate, not run Step 9 inline. The parser line must say
  # "delegate to /wr-itil:review-problems", matching the shape the
  # list-forwarder uses in slice 1. A stale "run the review (step 9)"
  # line would indicate the forwarder was added without updating the
  # parser (common slip).
  run grep -nE "^- If arguments contain \"review\", \*\*delegate to \`/wr-itil:review-problems\`\*\*" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}
