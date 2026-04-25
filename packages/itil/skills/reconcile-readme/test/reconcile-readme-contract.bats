#!/usr/bin/env bats
# Contract assertions for /wr-itil:reconcile-readme (P118).
#
# This skill wraps the diagnose-only `packages/itil/scripts/reconcile-readme.sh`
# script with an agent-applied-edits pattern. The contract here asserts the
# skill's structure (frontmatter, ADR pointers, invocation-surface
# enumeration) — the script's behaviour is asserted in
# packages/itil/scripts/test/reconcile-readme.bats per ADR-005.
#
# Structural assertion — Permitted Exception to the source-grep ban
# (ADR-005 / P011 / ADR-037 contract-assertion pattern).
#
# @problem P118
# @jtbd JTBD-006 (Progress the Backlog While I'm Away — orchestrators
# read README to pick highest-WSJF actionable ticket; drift burns iters)
# @jtbd JTBD-001 (Enforce Governance Without Slowing Down — read-only
# diagnostic, no interactive friction on the happy path)

setup() {
  SKILL_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  SKILL_FILE="${SKILL_DIR}/SKILL.md"
  REPO_ROOT="$(cd "${SKILL_DIR}/../../../.." && pwd)"
  SCRIPT="${REPO_ROOT}/packages/itil/scripts/reconcile-readme.sh"
}

# ── Frontmatter contract ────────────────────────────────────────────────────

@test "reconcile-readme: SKILL.md exists and has frontmatter" {
  [ -f "$SKILL_FILE" ]
  run head -1 "$SKILL_FILE"
  [ "$status" -eq 0 ]
  [ "$output" = "---" ]
}

@test "reconcile-readme: frontmatter name is wr-itil:reconcile-readme" {
  run grep -n "^name: wr-itil:reconcile-readme$" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "reconcile-readme: frontmatter description names the drift-correction intent (P118)" {
  run grep -E "^description: .*[Dd]rift" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "reconcile-readme: allowed-tools includes Read, Edit, Bash" {
  # Read for the ticket files. Edit for narrative-preserving row edits.
  # Bash for the script invocation. (Write is also present for the
  # rare case of an empty README rebuild.)
  run grep -E "^allowed-tools:.*Read.*Edit.*Bash" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

# ── Script wrapping contract ────────────────────────────────────────────────

@test "reconcile-readme: SKILL.md references the script path" {
  run grep -F "packages/itil/scripts/reconcile-readme.sh" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "reconcile-readme: the underlying script exists" {
  [ -f "$SCRIPT" ]
  [ -x "$SCRIPT" ]
}

@test "reconcile-readme: SKILL.md documents the three exit codes (0/1/2)" {
  # Exit-code semantics must be explicit so adopters know what to do
  # on parse error vs drift vs clean.
  run grep -E "exit.*\b0\b|^- \`0\`" "$SKILL_FILE"
  [ "$status" -eq 0 ]
  run grep -E "exit.*\b1\b|^- \`1\`" "$SKILL_FILE"
  [ "$status" -eq 0 ]
  run grep -E "exit.*\b2\b|^- \`2\`" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

# ── Narrative-preservation contract (architect Q2 verdict) ──────────────────

@test "reconcile-readme: SKILL.md asserts narrative preservation (no full regen)" {
  # Architect verdict (Q2): the skill+script split exists specifically
  # to preserve the README's "Last reviewed" prose paragraph and
  # Closed-section closure-via free text. A regression that introduces
  # full README regeneration would void the architect's choice.
  run grep -iE "preserve.*narrative|narrative.*preserve|do not regenerate|DO NOT regenerate" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

# ── Invocation-surface enumeration (architect Q3 verdict) ───────────────────

@test "reconcile-readme: SKILL.md names manage-problem Step 0 as one invocation surface" {
  run grep -E "manage-problem.*Step 0|Step 0.*manage-problem" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "reconcile-readme: SKILL.md names work-problems Step 0 as one invocation surface" {
  run grep -E "work-problems.*Step 0|Step 0.*work-problems" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "reconcile-readme: SKILL.md explicitly excludes transition-problem (P062 already covers transition refresh)" {
  # Architect Q3 verdict: transition-problem does NOT call this skill.
  # This is load-bearing — adding it would pay reconciliation cost on
  # every transition, redundant with P062.
  run grep -E "transition-problem.*does NOT|NOT call.*transition-problem|NO.*transition-problem" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

# ── ADR alignment ───────────────────────────────────────────────────────────

@test "reconcile-readme: SKILL.md cites ADR-014 (Reconciliation as preflight robustness layer)" {
  run grep -F "ADR-014" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "reconcile-readme: SKILL.md cites ADR-022 (Verification Pending lifecycle)" {
  run grep -F "ADR-022" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "reconcile-readme: SKILL.md cites ADR-038 (progressive disclosure / per-row byte budget)" {
  run grep -F "ADR-038" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "reconcile-readme: SKILL.md cites ADR-013 Rule 6 for AFK non-interactive auto-apply" {
  # The auto-apply branch in AFK mode must cite ADR-013 Rule 6
  # explicitly so the non-interactive fail-safe inheritance is
  # discoverable.
  run grep -E "ADR-013.*Rule 6|Rule 6.*ADR-013|Rule 6" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

# ── Composition with closed contracts (P094 + P062) ─────────────────────────

@test "reconcile-readme: SKILL.md asserts composition with P094 (robustness on top, not supersession)" {
  run grep -E "P094.*compose|compose.*P094|robustness.*on top|on top of P094" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "reconcile-readme: SKILL.md asserts composition with P062 (robustness on top, not supersession)" {
  run grep -E "P062.*compose|compose.*P062|on top of.*P062|P094.*P062" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

# ── Self-healing re-check after edits ───────────────────────────────────────

@test "reconcile-readme: SKILL.md mandates a re-run of the script after Step 4 edits land" {
  # The contract is self-healing only if the post-edit re-check fires.
  # Without it, a partial edit set ships silently.
  run grep -iE "re-run.*script|re.run.*reconcile-readme|re-run.*reconcile" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}
