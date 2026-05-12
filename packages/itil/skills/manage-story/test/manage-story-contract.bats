#!/usr/bin/env bats
# Behavioural contract fixtures for /wr-itil:manage-story (P170 Phase 2
# Slice 8 — ADR-060 amendment 2026-05-10 lines 200-253 + 270 + 292).
#
# Per ADR-052: behavioural assertions on observable SKILL contract
# surfaces. Skill-prose behaviour for prompt-driven agents isn't
# directly testable in bats; these tests assert presence of the
# load-bearing identifiers in the SKILL contract (the closest in-
# session-reachable approximation per P081 + P012).
#
# Behavioural surfaces under test:
#   1. SKILL.md presence + canonical name.
#   2. I6-I11 invariant table presence (load-bearing).
#   3. I7 + I8 hard-block fires at accepted transition (not earlier).
#   4. I10 INVEST shape gate names all 4 INVEST checks (Testable /
#      Valuable / Independent / Estimable) + L/XL decomposition-
#      candidate advisory per ADR-060 line 252 nitpick N3.
#   5. Auto-transition triggers named: draft→in-progress on first
#      non-capture commit; in-progress→done on criteria-ticked + RFC
#      closed.
#   6. Bootstrap-exemption marker contract named per ADR-060 line 339.
#   7. Reverse-trace refresh on all 4 parent tiers (problem / JTBD /
#      RFC / story-map) named, with story-map manual placement noted
#      per architect amend finding 2 on Slice 7.
#   8. No-WSJF-leak (I11) — no WSJF field in argument grammar or
#      frontmatter handling.
#
# @problem P170
# @jtbd JTBD-008 (Decompose a Fix Into Coordinated Changes)
# @jtbd JTBD-001 (extended scope — change-set-level governance)
# @adr  ADR-060  (Problem-RFC-Story framework — story tier)
# @adr  ADR-052  (Behavioural-tests-default)
# @adr  ADR-032  (governance-skill aside-invocation pattern)

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../../.." && pwd)"
  SKILL_FILE="${REPO_ROOT}/packages/itil/skills/manage-story/SKILL.md"
}

# ---------------------------------------------------------------------------
# Surface 0: SKILL.md presence + canonical name
# ---------------------------------------------------------------------------

@test "manage-story: SKILL.md exists" {
  [ -f "$SKILL_FILE" ]
}

@test "manage-story: SKILL.md frontmatter declares wr-itil:manage-story name" {
  run grep -E '^name: wr-itil:manage-story$' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Surface 1: I6-I11 invariant table presence
# ---------------------------------------------------------------------------

@test "manage-story: SKILL.md declares I6 trace-to-problem invariant" {
  run grep -E 'I6.*trace-to-problem|trace-to-problem.*I6' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "manage-story: SKILL.md declares I7 trace-to-RFC invariant" {
  run grep -E 'I7.*trace-to-RFC|trace-to-RFC.*I7' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "manage-story: SKILL.md declares I8 trace-to-story-map invariant" {
  run grep -E 'I8.*trace-to-story-map|trace-to-story-map.*I8' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "manage-story: SKILL.md declares I9 trace-to-JTBD invariant" {
  run grep -E 'I9.*trace-to-JTBD|trace-to-JTBD.*I9' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "manage-story: SKILL.md declares I10 INVEST shape invariant" {
  run grep -E 'I10.*INVEST|INVEST.*I10' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "manage-story: SKILL.md declares I11 no-WSJF-leak invariant" {
  run grep -E 'I11.*WSJF|WSJF.*I11|no-WSJF-leak' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Surface 2: I7 + I8 fire at accepted transition (not earlier)
# ---------------------------------------------------------------------------

@test "manage-story: SKILL.md states I7 + I8 hard-block fires at accepted transition" {
  # The deferred-from-capture contract is load-bearing per ADR-060
  # line 291 — capture-story permits absent traces; manage-story
  # accepted gate enforces them.
  run grep -iE 'I7.*accepted|hard-block at.*accepted|fires at.*accepted.*I7' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Surface 3: I10 INVEST 4-axis check
# ---------------------------------------------------------------------------

@test "manage-story: SKILL.md names all 4 INVEST checks (Testable/Valuable/Independent/Estimable)" {
  for axis in Testable Valuable Independent Estimable; do
    run grep -i "$axis" "$SKILL_FILE"
    [ "$status" -eq 0 ]
  done
}

@test "manage-story: SKILL.md names L/XL decomposition-candidate advisory per ADR-060 nitpick N3" {
  run grep -iE 'L/XL.*decomposition|decomposition.candidate|N3' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Surface 4: Auto-transition triggers
# ---------------------------------------------------------------------------

@test "manage-story: SKILL.md names draft → in-progress auto-transition on first non-capture commit" {
  run grep -iE 'draft.*in-progress.*first.*non-capture|first commit.*non-capture|first.*after.*capture' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "manage-story: SKILL.md names in-progress → done auto-transition on criteria-ticked + RFC closed" {
  run grep -iE 'in-progress.*done.*criteria.*ticked|all.*criteria.*ticked.*RFC.*closed|RFC.*closed.*all-criteria' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Surface 5: Bootstrap-exemption marker
# ---------------------------------------------------------------------------

@test "manage-story: SKILL.md names bootstrap-exemption marker per ADR-060 line 339" {
  run grep -iE 'bootstrap-exempt|bootstrap.exemption|ADR-053.*Bootstrapping' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Surface 6: Reverse-trace refresh on 4 parent tiers
# ---------------------------------------------------------------------------

@test "manage-story: SKILL.md names reverse-trace refresh on problem parents via update-problem-references-section.sh" {
  run grep -E 'update-problem-references-section\.sh.*Stories' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "manage-story: SKILL.md names reverse-trace refresh on JTBD parents via update-jtbd-references-section.sh" {
  run grep -E 'update-jtbd-references-section\.sh.*Stories' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "manage-story: SKILL.md names reverse-trace refresh on RFC parents via update-rfc-references-section.sh" {
  run grep -E 'update-rfc-references-section\.sh.*Stories' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "manage-story: SKILL.md names story-map parents as MANUAL placement (no automatic refresh per Slice 7 architect amend finding 2)" {
  run grep -iE 'manually-authored|manual placement|no automatic refresh' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Surface 7: I11 no-WSJF-leak — no WSJF field in argument grammar
# ---------------------------------------------------------------------------

@test "manage-story: SKILL.md argument grammar does NOT include a WSJF flag/token (I11 invariant)" {
  # The argument grammar block — extract the fenced block following
  # "## Argument grammar" and verify no WSJF token in it.
  run grep -A 20 '^## Argument grammar' "$SKILL_FILE"
  [[ "$output" != *"WSJF"* ]] && [[ "$output" != *"wsjf"* ]]
}
