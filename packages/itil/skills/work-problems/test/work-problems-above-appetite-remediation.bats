#!/usr/bin/env bats
# Doc-lint guard: work-problems SKILL.md must include the above-appetite
# auto-apply + halt-on-exhaustion branch per ADR-041.
#
# Structural assertion — Permitted Exception to the source-grep ban (ADR-005 / P011).
# These assertions are load-bearing-string checks on the skill specification
# document. Per P081, structural tests are placeholders for behavioural tests
# against P012's skill-testing harness; until that harness lands, these
# assertions are the confirmation mechanism called out in ADR-041 Confirmation
# criterion 2.
#
# Cross-reference:
#   P103 (work-problems escalates resolved release decisions — defeats AFK)
#   P104 (partial-progress paints release queue into corner)
#   P108 (scorer remediation action-class vocabulary — deferred work)
#   ADR-041 (auto-apply scorer remediations — never release above appetite)
#   ADR-037 (skill testing strategy — contract-assertion pattern)
#   @jtbd JTBD-006 (Progress the Backlog While I'm Away)

setup() {
  SKILL_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  SKILL_FILE="${SKILL_DIR}/SKILL.md"
}

@test "SKILL.md exists" {
  [ -f "$SKILL_FILE" ]
}

@test "SKILL.md cites ADR-041 (above-appetite auto-apply)" {
  # ADR-041 Confirmation criterion 1: source review names the ADR.
  run grep -n "ADR-041" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md contains the never-release-above-appetite invariant (Rule 1)" {
  # The load-bearing invariant from Rule 1. "MUST NOT release above appetite"
  # is the phrase that anchors the policy.
  run grep -nE "MUST NOT release above appetite" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md references RISK_REMEDIATIONS parsing contract (Rule 2)" {
  # Rule 2 parses RISK_REMEDIATIONS from the scorer. If the string is absent,
  # the skill does not implement the parse step.
  run grep -n "RISK_REMEDIATIONS" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md references docs/changesets-holding/ (Rule 2a move-to-holding class)" {
  # The one currently-implemented action class moves changesets to the holding
  # area. The path must be named so the skill body is unambiguous about target.
  run grep -n "docs/changesets-holding/" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md names the closed action-class enumeration (Rule 2a)" {
  # "move-to-holding" is the single supported class today; later P108 extends.
  # The string must appear so the enumeration is greppable.
  run grep -n "move-to-holding" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md names P108 (deferred action-class vocabulary)" {
  # Rule 2a defers revert-commit, amend-commit, feature-flag, rollback-to-tag
  # to P108. Keeping the reference greppable makes the deferral auditable.
  run grep -n "P108" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md includes the Verification Pending carve-out (Rule 2b)" {
  # Rule 2b prevents auto-revert of commits attached to .verifying.md tickets.
  run grep -niE "Verification Pending.*carve.out|Rule 2b|\.verifying\.md.*(skip|exclude|carve)" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md references the halt-on-exhaustion outcome (Rule 5)" {
  # Rule 5 emits outcome: halted-above-appetite when the auto-apply loop
  # exhausts without convergence.
  run grep -n "halted-above-appetite" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md cites ADR-013 Rule 5 (policy-authorised silent proceed)" {
  # Rule 1 is authorised by ADR-013 Rule 5. The citation should be explicit.
  run grep -nE "ADR-013 Rule 5" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md references the scorer-gap halt signal" {
  # Rule 5 treats exhaustion as a scorer-gap bug signal, not routine behaviour.
  run grep -niE "scorer.gap|scorer vocabulary|bug signal" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md Non-Interactive Decision Making table covers above-appetite auto-apply" {
  # The non-interactive defaults table row makes the behaviour discoverable to
  # an AFK reader without forcing a full prose read.
  run grep -niE "above appetite.*>= 5/25|pipeline risk above appetite|auto-apply scorer remediations" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md forbids AskUserQuestion shortcut for above-appetite" {
  # The anti-shortcut stance is load-bearing for P103. Absent this, the skill
  # reverts to the P103 bug. Allow optional "call "/"invoke " verb and optional
  # backtick around the tool name (since the SKILL.md phrasing treats it as code).
  run grep -niE "MUST NOT (call |invoke )?[\`]?AskUserQuestion" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md references the amend-based folding rule for ADR-032 compatibility (Rule 3)" {
  # Auto-apply commits fold into the iteration's main commit via amend so
  # ADR-032's one-commit-per-iteration invariant holds.
  run grep -niE "amend|git commit --amend" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md references the audit-trail subsection (Rule 6)" {
  # Rule 6 emits an Auto-apply trail subsection in the iteration summary. If
  # the phrase is missing, audit trail is not wired through.
  run grep -niE "Auto-apply trail|audit trail" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}
