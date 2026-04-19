#!/usr/bin/env bats
# Doc-lint guard: work-problems SKILL.md must surface outstanding design
# questions before emitting `ALL_DONE` at stop-condition #2. In AFK mode
# (the persona default per JTBD-006) the questions are listed in the
# post-stop summary as an "Outstanding Design Questions" table. In
# interactive invocations the skill may batch up to 4 questions through
# a single `AskUserQuestion` call per ADR-013 Rule 1.
#
# Structural assertion — Permitted Exception to the source-grep ban
# (ADR-005 / P011). These tests assert that the skill specification
# document contains the stop-condition #2 question-surfacing step and its
# supporting classifier taxonomy.
#
# Cross-reference:
#   P053: docs/problems/053-work-problems-does-not-surface-outstanding-design-questions-at-stop.open.md
#   ADR-013 Rule 1 / Rule 6: docs/decisions/013-structured-user-interaction-for-governance-decisions.proposed.md
#   ADR-018: docs/decisions/018-inter-iteration-release-cadence-for-afk-loops.proposed.md
#   @jtbd JTBD-006 (Progress the Backlog While I'm Away)
#   @jtbd JTBD-001 (Enforce Governance Without Slowing Down)

setup() {
  SKILL_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  SKILL_FILE="${SKILL_DIR}/SKILL.md"
}

@test "SKILL.md exists (P053 precondition)" {
  [ -f "$SKILL_FILE" ]
}

@test "SKILL.md stop-condition #2 has a pre-terminal question-surfacing step (P053)" {
  # P053 fix: between detecting stop-condition #2 and emitting `ALL_DONE`,
  # the skill must surface outstanding design questions. Accept a dedicated
  # "Step 2.5" heading OR equivalent wording that names the pre-terminal
  # question-batching step.
  run grep -inE "Step 2\.5|pre-terminal question|question-batching|outstanding design question|surface (the )?(outstanding )?questions? before ALL_DONE" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md stop-condition #2 cites the 4-question AskUserQuestion cap (P053 + ADR-013)" {
  # ADR-013 Rule 1 routes governance decisions through AskUserQuestion.
  # AskUserQuestion's documented per-call limit is 4 options. The
  # Step 2.5 block must name this cap so implementers do not silently
  # overflow.
  run grep -inE "cap at 4|up to 4 question|4 options? per AskUserQuestion|AskUserQuestion'?s? 4-(question|option) (limit|cap)|4-question cap|four questions? (per|at) a time" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md classifier records a skip-reason taxonomy (P053)" {
  # Step 4 classifier must distinguish user-answerable skips from
  # architect-design and upstream-blocked skips so Step 2.5 can select
  # the user-answerable subset. Accept either an explicit three-bucket
  # taxonomy OR the individual category names appearing near the
  # classifier.
  run grep -inE "user-answerable|user answerable" "$SKILL_FILE"
  [ "$status" -eq 0 ]
  run grep -inE "architect-design|architect design (judgment|required)" "$SKILL_FILE"
  [ "$status" -eq 0 ]
  run grep -inE "upstream-blocked|upstream blocked|upstream dependency" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md non-interactive fallback emits an Outstanding Design Questions table (P053 + ADR-013 Rule 6)" {
  # Rule 6: when AskUserQuestion is unavailable (AFK default per
  # JTBD-006), the skill must record the questions in the post-stop
  # summary rather than asking. Accept either literal "Outstanding
  # Design Questions" heading OR a named table with Ticket/Question
  # columns that carries the same semantics.
  run grep -inE "Outstanding Design Questions|outstanding.design.questions" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md stop-condition #2 cites ADR-013 Rule 6 fallback path (P053)" {
  # The fallback must be traceable to the ADR it honours. Require an
  # explicit Rule 6 citation in the stop-condition block.
  run grep -inE "ADR-013.*Rule 6|Rule 6.*ADR-013" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md Final Summary template includes the Outstanding Design Questions section when relevant (P053)" {
  # The Output Format block must show reviewers what the summary looks
  # like with outstanding questions attached — not just describe it in
  # prose elsewhere.
  run grep -n "### Outstanding Design Questions\|## Outstanding Design Questions" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}
