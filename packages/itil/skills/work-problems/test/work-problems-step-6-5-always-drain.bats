#!/usr/bin/env bats

# P250: /wr-itil:work-problems Step 6.5 release-cadence classification must
# pivot on releasable material, not residual band. The defective prior
# clause "Within appetite (≤ 3/25) — no drain needed" encoded
# accumulation-permitted-below-threshold semantics that violated the
# symmetric-balance principle (ADR-061 Rule 1) and the user's verbatim
# direction: "If it's low risk, you should release."
#
# Amended contract (three-band):
#   1. Above appetite (≥ 5/25)        → ADR-042 auto-apply (unchanged).
#   2. Within appetite (≤ 4/25) AND releasable material → drain.
#   3. Within appetite (≤ 4/25) AND empty queue        → no drain (no-op fast-path).
#
# The trigger for the drain action is *presence of releasable material*
# (any unpushed commits OR any .changeset/ entries OR any graduation-
# eligible held entries per ADR-061 Rule 1). The residual band remains
# the safety check (above-appetite never releases) but is no longer the
# action gate for the within-appetite branch.
#
# Doc-lint contract assertions per ADR-037 Permitted Exception (contract-
# assertion class). The asserted prose IS the load-bearing policy surface
# — re-reading SKILL.md is the only way an AFK reader (and the iteration
# subprocess) learns the new classification. Behavioural verification
# would require executing the orchestrator's decision tree, which is not
# scriptable until the Phase 2 advisory-classifier from P081 ships. These
# tests function as regression guards against re-introducing the
# "Within appetite (≤ 3/25) — no drain needed" wording or any equivalent
# threshold-as-action-gate framing.
#
# @problem P250
# @adr ADR-018 (release-cadence policy parent — amended in same commit)
# @adr ADR-037 (skill-testing strategy — contract-assertion class)
# @adr ADR-042 (above-appetite branch — preserved unchanged)
# @adr ADR-061 (Rule 1 symmetric-balance principle — parent principle)
# @jtbd JTBD-006 (Progress the Backlog While I'm Away — primary)
# @jtbd JTBD-002 (Ship with Confidence — composes; small frequent releases)

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../../.." && pwd)"
  SKILL_MD="$REPO_ROOT/packages/itil/skills/work-problems/SKILL.md"
  ADR_018="$REPO_ROOT/docs/decisions/018-inter-iteration-release-cadence-for-afk-loops.proposed.md"
}

# ── Preconditions ──────────────────────────────────────────────────────────

@test "work-problems P250: SKILL.md exists" {
  [ -f "$SKILL_MD" ]
}

@test "work-problems P250: ADR-018 exists" {
  [ -f "$ADR_018" ]
}

# ── Regression guard: defective prior wording is gone ──────────────────────

@test "work-problems P250: SKILL.md no longer contains 'Within appetite (≤ 3/25) — no drain needed' clause" {
  # The defective clause. Re-introducing it regresses to accumulation-
  # permitted-below-threshold semantics.
  run grep -nE 'Within appetite \(≤ 3/25\).*no drain needed' "$SKILL_MD"
  [ "$status" -ne 0 ]
}

@test "work-problems P250: SKILL.md no longer treats '= 4/25' as a discrete drain trigger band" {
  # The prior "At appetite (= 4/25) — drain" band is collapsed into the
  # new "≤ 4/25 AND releasable material" branch. The discrete = 4/25
  # framing should be absent from the Step 6.5 classification.
  run grep -nE 'At appetite \(= 4/25\) — drain' "$SKILL_MD"
  [ "$status" -ne 0 ]
}

# ── Above-appetite branch preserved (ADR-042) ──────────────────────────────

@test "work-problems P250: Above-appetite (≥ 5/25) branch routes to ADR-042 auto-apply (preserved)" {
  run grep -nE 'Above appetite \(≥ 5/25\).*Above-appetite branch' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "work-problems P250: Above-appetite branch references the auto-apply loop (ADR-042 intact)" {
  run grep -nE 'auto-apply loop|ADR-042' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

# ── Within-appetite + releasable material drains ──────────────────────────

@test "work-problems P250: Within-appetite + releasable material triggers drain" {
  # The load-bearing positive contract: within appetite AND any unpushed
  # commits OR changeset OR graduation-eligible held entry → drain.
  run grep -nE 'Within appetite \(≤ 4/25\) AND there is releasable material' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "work-problems P250: releasable-material clause enumerates unpushed commits" {
  run grep -nE 'releasable material.*unpushed commits|unpushed commits.*releasable material|any unpushed commits' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "work-problems P250: releasable-material clause enumerates .changeset/ entries" {
  run grep -nE 'any entries in `\.changeset/`|`\.changeset/` non-empty|entries in `\.changeset/`' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "work-problems P250: releasable-material clause enumerates ADR-061 Rule 1 graduation-eligible held entries" {
  # ADR-061 cross-reference: the symmetric-balance disjunct ensures
  # held entries that have decayed within appetite are graduation-
  # eligible AND drainable.
  run grep -nE 'graduation-eligible.*ADR-061 Rule 1|ADR-061 Rule 1.*graduation-eligible|docs/changesets-holding.*ADR-061' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

# ── Within-appetite + empty queue no-op fast-path ─────────────────────────

@test "work-problems P250: Within-appetite + empty queue does NOT drain (no-op fast-path)" {
  # The genuine fast-path: nothing to release. Gate is *absence of
  # releasable material*, not residual band.
  run grep -nE 'Within appetite \(≤ 4/25\) AND empty queue' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "work-problems P250: empty-queue branch is framed as 'literally nothing to release', not a threshold deferral" {
  # Regression guard: the no-drain branch must NOT be reframed as a
  # threshold-based defer. The gate is queue emptiness, not residual.
  run grep -nE 'literally nothing to release|nothing to release.*genuine no-op' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

# ── User-direction citation preserved ─────────────────────────────────────

@test "work-problems P250: amended classification cites user direction verbatim ('If it's low risk, you should release.')" {
  # The user's verbatim direction is the load-bearing rationale. Future
  # readers tracing the amendment back must find the citation without
  # keyword-guessing.
  run grep -nE 'If it.s low risk, you should release' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "work-problems P250: classification cites P250 by ticket ID" {
  # ADR-022 amendment trail: the amended clause must self-identify
  # so future readers tracing back from the ticket find it.
  run grep -nE 'P250' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

# ── Non-Interactive Decision Making table reflects amendment ──────────────

@test "work-problems P250: Decision Making table carries the within-appetite-with-releasable-material row" {
  # The decision table is the AFK reader's quick-reference; the
  # amendment must surface here too, otherwise the table contradicts
  # Step 6.5's classification.
  run grep -nE '\| Pipeline risk within appetite \(≤ 4/25\) with releasable material' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "work-problems P250: Decision Making table carries the empty-queue no-drain row" {
  run grep -nE '\| Pipeline risk within appetite \(≤ 4/25\) AND empty queue' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "work-problems P250: Decision Making table row cites 'presence of releasable material', not 'residual reaching appetite'" {
  # The trigger semantics must be explicit in the table row, not
  # buried in Step 6.5 prose 100+ lines above.
  run grep -nE 'presence of releasable material|releasable material.*not residual band|Trigger is.*presence' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

# ── ADR-018 amendment (in same commit per ADR-014) ────────────────────────

@test "work-problems P250: ADR-018 contains the 2026-05-18 Drain-trigger amendment heading" {
  # ADR-014 single-unit-of-work: the ADR amendment lands in the same
  # commit as the SKILL change. ADR-018's Mechanism without this
  # amendment contradicts SKILL.md Step 6.5.
  run grep -nE 'Amendment 2026-05-18.*Drain trigger is releasable material' "$ADR_018"
  [ "$status" -eq 0 ]
}

@test "work-problems P250: ADR-018 amendment cites P250 by ticket ID" {
  run grep -nE 'P250' "$ADR_018"
  [ "$status" -eq 0 ]
}

@test "work-problems P250: ADR-018 amendment quotes the user direction" {
  run grep -nE 'If it.s low risk, you should release' "$ADR_018"
  [ "$status" -eq 0 ]
}

@test "work-problems P250: ADR-018 amendment encodes the new drain condition shape" {
  # The amendment must contain the conjunction "≤ 4/25 AND (releasable
  # material disjunct)" so future readers tracing the policy chain
  # find the rule in the load-bearing ADR, not just in the SKILL.
  run grep -nE 'residual ≤ 4/25 AND' "$ADR_018"
  [ "$status" -eq 0 ]
}

@test "work-problems P250: ADR-018 amendment preserves Above-appetite delegation to ADR-042" {
  # The amendment MUST NOT touch the above-appetite invariant. ADR-042
  # remains the safety gate.
  run grep -nE 'Above-appetite states \(≥ 5/25\) route to ADR-042|Above-appetite.*ADR-042' "$ADR_018"
  [ "$status" -eq 0 ]
}

# ── Cross-references intact ───────────────────────────────────────────────

@test "work-problems P250: SKILL.md Step 6.5 still cites ADR-018 (parent policy intact)" {
  run grep -nE 'Step 6\.5.*ADR-018|ADR-018.*Step 6\.5|Release-cadence check.*ADR-018' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "work-problems P250: SKILL.md Step 6.5 still cites P041 (accumulation root cause cross-reference)" {
  # P041 is the ancestor that established Step 6.5 itself. The
  # amendment refines P041's solution; the cross-reference must
  # survive.
  run grep -nE 'P041' "$SKILL_MD"
  [ "$status" -eq 0 ]
}
