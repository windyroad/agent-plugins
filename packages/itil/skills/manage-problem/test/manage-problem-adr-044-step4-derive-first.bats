#!/usr/bin/env bats
# ADR-044 alignment contract assertions for manage-problem SKILL.md
# Step 4 (P132 Phase 2a-ii derive-first refactor, 2026-05-15).
#
# tdd-review: structural-permitted (justification: SKILL.md prose contract
# assertions; behavioural skill-runtime harness pending P012 + P081 Phase 2;
# expected to migrate to behavioural form once the harness exists. Added
# during P132 Phase 2a-ii per the inline plan's bridge-marker rule —
# isomorphic precedent at manage-incident-adr-044-contract.bats Surface 2.)
#
# This file is the dedicated structural-grep-permitted home for the ADR-044
# alignment contract during the bridge window. After P081 Phase 2 retrofits
# the project's structural-grep tests to behavioural form, this file's
# assertions migrate too.
#
# @problem P132 (agents over-ask in interactive sessions — Phase 2a-ii
#   manage-problem create flow derive-first refactor)
# @problem P185 (capture-problem Step 1.5 worked-example precedent)
# @problem P136 (ADR-044 alignment audit master)
# @adr ADR-044 (Decision-Delegation Contract)
# @adr ADR-013 amended Rule 1 (structured user interaction)
# @adr ADR-026 (cost-source grounding — stderr advisory shape)
# @adr ADR-052 (behavioural-by-default with structural bridge window)
# @jtbd JTBD-001 (enforce governance without slowing down — primary)
# @jtbd JTBD-006 (work backlog AFK — queued for return, not guessed at)
# @jtbd JTBD-101 (extend the suite with consistent patterns)

setup() {
  SKILL_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  SKILL_FILE="${SKILL_DIR}/SKILL.md"
  [ -f "$SKILL_FILE" ]
}

# ----------------------------------------------------------------------
# Step 4 derive-first refactor (P132 Phase 2a-ii) — cat-4 silent-framework
# on Title + Priority-when-evidence-present; cat-1 direction-setting only
# on Description; cat-5 taste fallback only on Priority-when-ambiguous.
# ----------------------------------------------------------------------

@test "SKILL.md Step 4 cross-references ADR-044 category-4 (silent-framework) for derivable fields (P132 derive-first)" {
  # P132 Phase 2a-ii: Title + Priority-when-evidence-present resolve via
  # silent-framework per ADR-044 category 4. Only Description retains
  # AskUserQuestion as genuine cat-1 direction-setting (no prose -> nothing
  # to capture).
  run awk '/^### 4\. /,/^### 4b\. /' "$SKILL_FILE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"silent-framework"* ]] || [[ "$output" == *"category 4"* ]] || [[ "$output" == *"category-4"* ]]
}

@test "SKILL.md Step 4 cross-references ADR-044 category-1 (direction-setting) for Description fallback" {
  # Description is the genuine cat-1 surface — without prose there is
  # literally nothing to capture. The refactor preserves the AskUserQuestion
  # on Description.
  run awk '/^### 4\. /,/^### 4b\. /' "$SKILL_FILE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"direction-setting"* ]] || [[ "$output" == *"category 1"* ]] || [[ "$output" == *"category-1"* ]]
}

@test "SKILL.md Step 4 derives Title from prose silently (P132 inverse-P078)" {
  # The 2026-05-06 I001 declaration regression cited in P132 line 14 was the
  # same agent failure mode on the manage-incident surface: agent asked
  # "Title" with 3 candidate options when kebab-casing the description
  # would have produced the slug directly. manage-problem Step 4 must ship
  # the same derive-first pattern.
  run awk '/^### 4\. /,/^### 4b\. /' "$SKILL_FILE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Title"* ]]
  [[ "$output" == *"derive"* ]] || [[ "$output" == *"derived"* ]]
  [[ "$output" == *"kebab"* ]] || [[ "$output" == *"prose"* ]]
}

@test "SKILL.md Step 4 derives Priority from RISK-POLICY matrix + evidence (P132 inverse-P078)" {
  # The I001 regression cited in P132 line 15 was the analogous failure on
  # Severity. manage-problem's Priority (Impact x Likelihood) derives from
  # the same RISK-POLICY matrix lookup against description signals.
  # Ambiguous-evidence falls back to AskUserQuestion as cat-5 (taste).
  run awk '/^### 4\. /,/^### 4b\. /' "$SKILL_FILE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Priority"* ]]
  [[ "$output" == *"RISK-POLICY"* ]]
}

@test "SKILL.md Step 4 retains Description as AskUserQuestion fallback (negative-of-negative guard)" {
  # Regression-resistance: the refactor MUST preserve the genuine cat-1
  # direction-setting surface on Description. Without user-supplied prose
  # the SKILL has nothing to derive from — Description IS the input. Same
  # reasoning as manage-incident Step 4 Scope retention.
  run awk '/^### 4\. /,/^### 4b\. /' "$SKILL_FILE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Description"* ]]
  [[ "$output" == *"AskUserQuestion"* ]]
}

@test "SKILL.md Step 4 cites P132 (inverse-P078 audit traceability)" {
  # P132 + ADR-044 must appear in Step 4 or Related section so the audit
  # trail for the Phase 2a-ii refactor is recoverable from the SKILL.md
  # surface.
  run grep -nE "P132" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md Step 4 documents stderr advisory shape for derived fields (ADR-026 grounding)" {
  # ADR-026 cost-source grounding: each silent derivation emits a stderr
  # advisory citing the source. Pattern parity with capture-problem Step
  # 1.5 + manage-incident Step 4 (I2-isomorphic across the three
  # declaration-skill surfaces per architect verdict 2026-05-15).
  run awk '/^### 4\. /,/^### 4b\. /' "$SKILL_FILE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"stderr"* ]] || [[ "$output" == *"advisory"* ]]
}

@test "SKILL.md Step 4 cross-references capture-problem Step 1.5 + manage-incident Step 4 (cross-skill consistency)" {
  # The architect verdict 2026-05-15 P132 Phase 2a-ii flagged cross-skill
  # consistency: three declaration-skill surfaces now ship the same
  # dispatch shape. The Step 4 prose must explicitly cite both prior
  # surfaces (P185 capture-problem + manage-incident b7cc645) as
  # worked-example precedents so the I2-isomorphic stderr advisory format
  # is locked-in by reference before a fourth surface (Phase 2a-iii
  # create-adr) drifts.
  run awk '/^### 4\. /,/^### 4b\. /' "$SKILL_FILE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"P185"* ]] || [[ "$output" == *"capture-problem"* ]]
  [[ "$output" == *"manage-incident"* ]] || [[ "$output" == *"b7cc645"* ]]
}

# ----------------------------------------------------------------------
# Negative-of-negative guards — Step 4b multi-concern + Step 2
# duplicate-check MUST remain cat-1 direction-setting AskUserQuestion
# surfaces (architect verdict 2026-05-15: not touched by Phase 2a-ii).
# ----------------------------------------------------------------------

@test "SKILL.md Step 4b multi-concern AskUserQuestion is preserved (cat-1 direction-setting, not touched by Phase 2a-ii)" {
  # Architect verdict 2026-05-15: Step 4b is a separate cat-1
  # direction-setting surface — only the user knows whether the concerns
  # can be independently fixed. The Phase 2a-ii refactor MUST NOT touch
  # Step 4b's AskUserQuestion gate.
  run awk '/^### 4b\. /,/^### 5\. /' "$SKILL_FILE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"AskUserQuestion"* ]]
  [[ "$output" == *"concern"* ]] || [[ "$output" == *"split"* ]]
}

@test "SKILL.md Step 2 duplicate-check AskUserQuestion is preserved (cat-1 direction-setting, not touched by Phase 2a-ii)" {
  # Architect verdict 2026-05-15: Step 2 is a separate cat-1
  # direction-setting surface — only the user knows whether an existing
  # ticket is the same root cause. The Phase 2a-ii refactor MUST NOT
  # touch Step 2's AskUserQuestion gate.
  run awk '/^### 2\. /,/^### 3\. /' "$SKILL_FILE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"AskUserQuestion"* ]]
}
