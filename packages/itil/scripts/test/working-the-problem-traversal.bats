#!/usr/bin/env bats
# Behavioural fixtures for the Phase 2 working-the-problem traversal
# rewrite (P170 Phase 2 Slice 13 — ADR-060 lines 300-320).
#
# Per ADR-052: behavioural assertions on observable artefact + skill
# contract state. The load-bearing surfaces under test are:
#   1. manage-problem § Working a Problem → Known Error subsection names
#      the four traversal steps (Fix Strategy → RFCs → stories: array →
#      pick first not-done) + the two fallback paths (atomic-RFC empty
#      stories: [], legacy no-RFC Fix Strategy).
#   2. work-problem § Step 3 Known Error case names the same traversal
#      and forward-points to manage-problem as the contract owner.
#   3. The single-trailer vocabulary holds — `Refs: STORY-NNN` for
#      story-decomposed work, `Refs: RFC-NNN` for atomic-RFC fallback,
#      `Refs: P<NNN>` for legacy direct work (single trailer verb per
#      ADR-060 line 307).
#   4. Story auto-transition triggers are named: draft → in-progress
#      on first non-capture commit; in-progress → done on
#      all-criteria-ticked + linked RFC closed.
#
# @problem P170
# @jtbd JTBD-008 (Decompose a Fix Into Coordinated Changes — traversal
#                  operationalises the "first-class entity" Desired
#                  Outcome at implementation time)
# @jtbd JTBD-101 (atomic-fix-adopter friction guard — empty stories: []
#                  falls back to per-RFC dispatch without friction)
# @adr  ADR-060  (Problem-RFC-Story framework — working-the-problem
#                  flow lines 300-320 + amendment 2026-05-10 nitpick N2
#                  single-trailer vocabulary)
# @adr  ADR-052  (Behavioural-tests-default)

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../.." && pwd)"
  MANAGE_PROBLEM="${REPO_ROOT}/packages/itil/skills/manage-problem/SKILL.md"
  WORK_PROBLEM="${REPO_ROOT}/packages/itil/skills/work-problem/SKILL.md"
}

# ---------------------------------------------------------------------------
# Surface 1: manage-problem § Working a Problem → Known Error names the
# 4-step traversal (Fix Strategy → RFCs → stories: → pick first not-done)
# ---------------------------------------------------------------------------

@test "traversal: manage-problem names the Fix Strategy section extraction step" {
  run grep -E 'Read the problem.*\#\# Fix Strategy.*RFC' "$MANAGE_PROBLEM"
  [ "$status" -eq 0 ]
}

@test "traversal: manage-problem names the RFC frontmatter stories: array read step" {
  run grep -E 'frontmatter stories:.*ORDERED|stories:.*array.*execution sequence' "$MANAGE_PROBLEM"
  [ "$status" -eq 0 ]
}

@test "traversal: manage-problem names the pick-first-not-done filter (accepted or in-progress)" {
  run grep -E 'accepted.*in-progress.*done.*draft|first story whose.*status is.*accepted' "$MANAGE_PROBLEM"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Surface 2: manage-problem names BOTH fallback paths
# ---------------------------------------------------------------------------

@test "traversal: manage-problem names the atomic-RFC empty stories: [] fallback (JTBD-101 friction guard)" {
  run grep -E 'atomic-RFC fallback|atomic RFC.*JTBD-101.*friction guard|stories: \[\].*atomic' "$MANAGE_PROBLEM"
  [ "$status" -eq 0 ]
}

@test "traversal: manage-problem names the legacy no-RFC direct-implementation fallback" {
  run grep -iE 'legacy direct-implementation|no-RFC.*legacy|no RFCs.*direct' "$MANAGE_PROBLEM"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Surface 3: work-problem § Step 3 Known Error case forwards to manage-problem
# ---------------------------------------------------------------------------

@test "traversal: work-problem Step 3 Known Error case names the traversal chain" {
  # The traversal description must include all four chain elements:
  # Fix Strategy, RFCs, stories: array, pick first not-done.
  run grep -iE 'Fix Strategy.*stories:.*pick first|traverse.*Fix Strategy.*RFC.*stories' "$WORK_PROBLEM"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Surface 4: Single-trailer vocabulary (per ADR-060 line 307 + N2 amendment)
# ---------------------------------------------------------------------------

@test "traversal: manage-problem names Refs: STORY-NNN trailer for story-decomposed work" {
  run grep -E 'Refs: STORY-' "$MANAGE_PROBLEM"
  [ "$status" -eq 0 ]
}

@test "traversal: manage-problem names Refs: RFC-NNN trailer for atomic-RFC fallback" {
  run grep -E 'Refs: RFC-' "$MANAGE_PROBLEM"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Surface 5: Story auto-transition triggers
# ---------------------------------------------------------------------------

@test "traversal: manage-problem names the story draft → in-progress auto-transition trigger" {
  run grep -iE 'draft.*in-progress.*first.*commit|auto-transitions.*draft.*in-progress' "$MANAGE_PROBLEM"
  [ "$status" -eq 0 ]
}

@test "traversal: manage-problem names the in-progress → done auto-transition trigger (criteria ticked + RFC closed)" {
  run grep -iE 'in-progress.*done.*acceptance-criteria.*ticked|ALL acceptance-criteria.*RFC reaches.*closed' "$MANAGE_PROBLEM"
  [ "$status" -eq 0 ]
}
