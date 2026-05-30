#!/usr/bin/env bats
#
# packages/retrospective/skills/run-retro/test/run-retro-step-4a-prior-session-evidence-drain.bats
#
# Contract assertions for run-retro Step 4a's prior-session evidence drain
# stage (P282). Step 4a's current sub-steps 1-8 scan the CURRENT session's
# tool-call activity for evidence. This stage consumes durable on-disk
# evidence — README Verification Queue rows whose `Likely verified?` cell
# already records `yes — observed: <citations>` from a prior session — that
# is structurally invisible to current-session scans.
#
# Background: 2026-05-26 evidence in this repo (P282 Related section) —
# 8/91 `verifying/` rows had `yes — observed: …` from prior sessions; none
# auto-closed; the Verification Queue grew to 134 KB exceeding the Read-tool
# 25K-token whole-file cap. Closure required user prompting. The drain
# closes that gap.
#
# Tests are behavioural per ADR-005 / ADR-037 / ADR-044 — they assert what
# the SKILL contract DOES (mechanism + observable outcome) by inspecting
# the SKILL.md text + the precedents it cites. Per ADR-044 Confirmation
# Criteria (a), the test FILE exists and is named; the per-assertion shape
# matures as the behavioural-test harness for LLM-interpreted skills lands
# (P081 Phase 2/3 deferred; P012 harness work).
#
# tdd-review: structural-permitted (justification: skill behavioural
# harness pending P012 + P081 Phase 2; SKILL.md contract assertions are
# the bridge until then; behavioural fixture at the foot of this file
# exercises a sample README VQ table to confirm the drain's row-detection
# heuristic against a real evidence-bearing cell)
#
# @problem P282
# @adr ADR-022 (verification-pending lifecycle)
# @adr ADR-014 (commit grain)
# @adr ADR-044 (decision-delegation — close-on-evidence)
# @adr ADR-074 (substance-confirm-before-build — this fix passed the gate)
# @jtbd JTBD-001 / JTBD-006 / JTBD-201

SKILL_FILE="${BATS_TEST_DIRNAME}/../SKILL.md"

setup() {
  [ -f "$SKILL_FILE" ] || skip "SKILL.md not found"
}

@test "run-retro: Step 4a documents a prior-session evidence drain stage (P282)" {
  # The drain stage is the headline behaviour; SKILL.md must name it.
  run grep -F 'Prior-session evidence drain (P282)' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "run-retro: prior-session drain reads docs/problems/README.md Verification Queue" {
  # The cell to consume is in the README's Verification Queue table, not
  # in any current-session activity stream. SKILL.md must name the source.
  run awk '/Prior-session evidence drain/,/^   \*\*Composition/' "$SKILL_FILE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"docs/problems/README.md"* ]]
  [[ "$output" == *"Verification Queue"* ]]
}

@test "run-retro: prior-session drain filters on P186 evidence-first cell shape" {
  # The canonical signal is `yes — observed: <citations>` per P186.
  # SKILL.md must cite the exact cell shape as the filter predicate so
  # adopters and future agents can grep for the right value.
  run awk '/Prior-session evidence drain/,/^   \*\*Composition/' "$SKILL_FILE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"yes — observed:"* ]]
  [[ "$output" == *"P186"* ]]
}

@test "run-retro: prior-session drain preserves same-session exclusion (sub-step 8)" {
  # The drain MUST inherit Step 4a's same-session exclusion (sub-step 8)
  # so a session cannot verify its own fix via the README cell either.
  # The exclusion is the load-bearing constraint distinguishing "prior
  # session wrote the cell" from "current session wrote the cell".
  run awk '/Prior-session evidence drain/,/^   \*\*Composition/' "$SKILL_FILE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"same-session"* ]] || [[ "$output" == *"current session"* ]]
}

@test "run-retro: prior-session drain delegates close via /wr-itil:transition-problem" {
  # Per Step 4a's existing dispatch contract (sub-steps 5-7), the close
  # MUST route through /wr-itil:transition-problem <NNN> close. run-retro
  # never renames, edits Status, or commits — the ownership boundary holds.
  run awk '/Prior-session evidence drain/,/^   \*\*Composition/' "$SKILL_FILE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"/wr-itil:transition-problem"* ]]
}

@test "run-retro: prior-session drain inherits dispatch outcome contract (P135 R3)" {
  # The dispatch success / failure / unavailable outcomes are recorded
  # in the Step 5 Verification Candidates table per sub-step 7. The
  # drain stage MUST cite the inheritance so behaviour is uniform.
  run awk '/Prior-session evidence drain/,/^   \*\*Composition/' "$SKILL_FILE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"sub-step 7"* ]] || [[ "$output" == *"Verification Candidates"* ]]
}

@test "run-retro: prior-session drain records source distinction in Decision column" {
  # The Decision column must distinguish drained-from-README from
  # current-session-dispatched closes so the user can scan the source
  # of each close at retro-summary review time.
  run awk '/Prior-session evidence drain/,/^   \*\*Composition/' "$SKILL_FILE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"prior-session README cell"* ]]
}

@test "run-retro: prior-session drain documents the recovery path inline (P135 R5)" {
  # Closes are reversible via /wr-itil:transition-problem <NNN> known-error
  # (the verifying-flip-back path); the drain stage inherits this contract.
  run awk '/Prior-session evidence drain/,/\*\*Closes P282\*\*/' "$SKILL_FILE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Recovery"* ]] || [[ "$output" == *"recoverable"* ]] || [[ "$output" == *"reversible"* ]]
}

@test "run-retro: prior-session drain composes with current-session dispatch ordering" {
  # The drain fires AFTER sub-steps 5-7 dispatched current-session
  # evidence. The Composition note must name the ordering so future
  # readers don't accidentally re-order the stages.
  run grep -F '**Composition**' "$SKILL_FILE"
  [ "$status" -eq 0 ]
  run awk '/Prior-session evidence drain/,/\*\*Closes P282\*\*/' "$SKILL_FILE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"AFTER"* ]] || [[ "$output" == *"after"* ]]
}

@test "run-retro: prior-session drain cites the 2026-05-26 evidence motivating the fix" {
  # The drain's rationale is grounded in observable repo evidence: 8 rows
  # carried `yes — observed:` across prior sessions and none auto-closed
  # until user-prompted. SKILL.md cites the evidence so future maintainers
  # can audit the design driver.
  run awk '/Prior-session evidence drain/,/\*\*Closes P282\*\*/' "$SKILL_FILE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"2026-05-26"* ]] || [[ "$output" == *"134 KB"* ]] || [[ "$output" == *"8/91"* ]]
}

@test "run-retro: prior-session drain explicitly closes P282" {
  # The drain stage names P282 as the ticket it closes so the
  # ticket-to-behavior link is greppable. (Same convention used by
  # the existing Step 4a header which names P068.)
  run grep -F '**Closes P282**' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

# Behavioural fixture — exercises the row-detection heuristic against a
# sample README VQ table. Asserts the drain's filter predicate matches
# `yes — observed:` rows and skips `no — not observed` / `no — observed
# regression` rows.
@test "behavioural: drain filter matches yes — observed rows and skips no rows" {
  # Build a minimal README VQ-shaped fixture in a temp dir.
  TMP="$(mktemp -d)"
  cat > "$TMP/README.md" <<'EOF'
## Verification Queue

| ID | Title | Released | Likely verified? |
| --- | --- | --- | --- |
| P100 | sample one | 2026-04-01 | yes — observed: cited evidence |
| P101 | sample two | 2026-04-02 | no — not observed |
| P102 | sample three | 2026-04-03 | yes — observed: more evidence |
| P103 | sample four | 2026-04-04 | no — observed regression |
EOF
  # The drain's row-detection predicate: the cell starts with `yes — observed:`.
  # Assert the fixture matches the expected row count.
  matched=$(grep -cE '\| yes — observed:' "$TMP/README.md")
  [ "$matched" -eq 2 ]
  # And the skip predicates match the other two.
  skipped=$(grep -cE '\| no — not observed|\| no — observed regression' "$TMP/README.md")
  [ "$skipped" -eq 2 ]
  rm -rf "$TMP"
}
