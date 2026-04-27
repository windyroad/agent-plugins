#!/usr/bin/env bats
# Contract assertions for /wr-itil:mitigate-incident (P071 split slice 6a).
#
# This skill hosts the "mitigate an incident" user intent previously
# hidden behind /wr-itil:manage-incident <I> mitigate <action>. It records
# a mitigation attempt, transitions an incident from .investigating.md to
# .mitigating.md (first mitigation only), and appends the attempt + outcome
# to the Mitigation attempts timeline per ADR-011.
#
# Structural assertion — Permitted Exception to the source-grep ban
# (ADR-005 / P011 / ADR-037 contract-assertion pattern).
#
# tdd-review: structural-permitted (justification: SKILL.md prose contract
# assertions; behavioural skill-runtime harness pending P012 + P081 Phase 2;
# expected to migrate to behavioural form once the harness exists. Touched
# during P136 Phase 2 ADR-044 alignment audit per the inline plan's
# bridge-marker rule.)
#
# @problem P071 (originating split)
# @problem P136 (ADR-044 alignment audit master — Phase 2 mitigate-incident)
# @adr ADR-044 (Decision-Delegation Contract — argument-backfill is framework-mediated; evidence-gate is cat-2 deviation-approval; risk-above-appetite commit is cat-3 one-time-override)
# @jtbd JTBD-001 (enforce governance without slowing down — discoverable surface)
# @jtbd JTBD-101 (extend the suite with clear patterns — one skill per distinct user intent; consistent argument-backfill with transition-problem / work-problem)
# @jtbd JTBD-201 (restore service fast with an audit trail — mitigation + evidence gate; fail-fast on typos preserves "restore fast")
#
# Cross-reference:
#   P071: docs/problems/071-argument-based-skill-subcommands-are-not-discoverable.open.md
#   P136: docs/problems/136-adr-044-alignment-audit-master.open.md
#   ADR-010 amended (Skill Granularity section) — split naming + forwarder contract
#   ADR-011 — manage-incident skill-wrapping precedent (evidence-gate, reversible preference)
#   ADR-013 amended Rule 1 — structured user interaction; framework-resolution narrowing per ADR-044
#   ADR-037 — contract-assertion bats pattern
#   ADR-044 — Decision-Delegation Contract; argument-backfill is mechanical (Surface 1); evidence-gate is cat-2 (Surface 2); risk-above-appetite is cat-3 (Surface 3)

setup() {
  SKILL_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  SKILL_FILE="${SKILL_DIR}/SKILL.md"
}

@test "SKILL.md exists and has frontmatter" {
  [ -f "$SKILL_FILE" ]
  run head -1 "$SKILL_FILE"
  [ "$status" -eq 0 ]
  [ "$output" = "---" ]
}

@test "SKILL.md frontmatter name is wr-itil:mitigate-incident (P071 + ADR-010 amended)" {
  # Split naming convention per ADR-010 amendment: <verb>-<object> pair.
  # The new skill's name must match the phased-landing plan pinned in P071.
  run grep -n "^name: wr-itil:mitigate-incident$" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md frontmatter description names the mitigate intent (P071)" {
  # Description must name "mitigate" and "incident" so Claude Code autocomplete
  # surfaces the user intent rather than a generic name.
  run grep -inE "^description:.*mitigat.*incident|^description:.*incident.*mitigat" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md frontmatter allowed-tools grants file-mutation surface (P071 — mitigate requires rename + edit)" {
  # Unlike list-incidents (read-only), mitigate-incident renames
  # .investigating.md → .mitigating.md, updates the Status field, and
  # appends to Mitigation attempts. It must declare Write + Edit + Bash
  # (for git mv) in its allowed-tools. AskUserQuestion is required for
  # the evidence-gate pre-flight prompt per ADR-011 when a hypothesis
  # lacks cited evidence.
  run grep -nE "^allowed-tools:" "$SKILL_FILE"
  [ "$status" -eq 0 ]
  run grep -nE "^allowed-tools:.*Write" "$SKILL_FILE"
  [ "$status" -eq 0 ]
  run grep -nE "^allowed-tools:.*Edit" "$SKILL_FILE"
  [ "$status" -eq 0 ]
  run grep -nE "^allowed-tools:.*Bash" "$SKILL_FILE"
  [ "$status" -eq 0 ]
  run grep -nE "^allowed-tools:.*AskUserQuestion" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md documents the evidence-gate pre-flight (P071 + ADR-011)" {
  # Per ADR-011's "Do not act on a hypothesis without at least one cited
  # evidence source" rule, mitigate-incident's pre-flight must block the
  # first mitigation attempt when no hypothesis has cited evidence.
  # The SKILL.md must name the gate explicitly so the audit-trail
  # invariant (JTBD-201) is legible.
  run grep -inE "evidence|hypothes" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md documents the .investigating.md → .mitigating.md rename (P071 + ADR-011)" {
  # The first mitigation attempt transitions the incident file from
  # .investigating.md to .mitigating.md. Subsequent mitigations append
  # to the existing .mitigating.md. The SKILL.md must name both
  # suffixes explicitly so the file-suffix contract is legible.
  run grep -inE "\.investigating\.md" "$SKILL_FILE"
  [ "$status" -eq 0 ]
  run grep -inE "\.mitigating\.md" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md documents the reversible-mitigation preference (P071 + ADR-011)" {
  # Per ADR-011, mitigate-incident prefers reversible mitigations
  # (rollback → feature flag → restart → route traffic → scale → fix)
  # over forward fixes. The SKILL.md must name the preference so the
  # cool-headed-commitment invariant is preserved post-split.
  run grep -inE "reversible|rollback" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md documents the Mitigation attempts timeline append (P071 + ADR-011)" {
  # Every mitigation attempt, successful or not, must append a
  # [timestamp] action → outcome row to the Mitigation attempts section.
  # The SKILL.md must name the append contract so future maintainers
  # don't drop failed-attempt recording.
  run grep -inE "[Mm]itigation attempt" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md cites P071 and ADR-010 amended (P071 + ADR-025)" {
  # ADR-025 inheritance per ADR-037: contract-assertion bats should reflect
  # traceability cites on the skill spec document.
  run grep -inE "P071|ADR-010" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md cites ADR-011 for the incident lifecycle conventions (P071 + ADR-011)" {
  # mitigate-incident inherits file-suffix conventions and the
  # evidence-first rule from ADR-011. The SKILL.md must cite ADR-011
  # so the precedent chain is legible.
  run grep -inE "ADR-011" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md does not carry a deprecated-arguments frontmatter flag (clean-split skill)" {
  # mitigate-incident is a clean-split skill with no argument-subcommands
  # itself (its arguments are data parameters — incident ID + action).
  # ADR-010 amendment's `deprecated-arguments: true` flag is only valid
  # on host skills with forwarder routes. mitigate-incident is a
  # forwarder TARGET, not a host. It must NOT carry the flag.
  run grep -E "^deprecated-arguments:" "$SKILL_FILE"
  [ "$status" -ne 0 ]
}

@test "SKILL.md does not use word-argument subcommand branching (P071 regression guard)" {
  # The whole point of P071: Claude Code autocomplete does not surface
  # word-argument subcommands. A clean-split skill must not reintroduce
  # word-arg subcommand routing (e.g. `list` / `mitigate` / `restore`).
  # The data parameters <I> and <action> are strings, not verb keywords,
  # so the anti-pattern is patterns like `If arguments start with "list"`.
  run grep -inE "If arguments start with \"(list|mitigate|restore|close|link)\"|If arguments contain \"(list|mitigate|restore|close|link)\"" "$SKILL_FILE"
  [ "$status" -ne 0 ]
}

@test "SKILL.md documents the low-severity lightweight path (P071 + ADR-011 edge case)" {
  # ADR-011's Step 12 edge case: for Sev 4-5 incidents, the Hypotheses
  # section may be skipped if the user confirms no investigation is
  # needed. Timeline, Observations, and at least one mitigation attempt
  # remain mandatory. The split skill must preserve this lightweight
  # path so JTBD-001's "without slowing down" outcome holds during
  # low-severity incidents.
  run grep -inE "lightweight|low.?severity|Sev 4|Sev 5" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

# ----------------------------------------------------------------------
# P136 Phase 2 — ADR-044 alignment audit (added 2026-04-27)
#
# These assertions land the framework-mediated argument-backfill contract
# (Surface 1 — fail-fast on typo-class input; matches transition-problem
# / work-problem precedent), and the ADR-044 cross-references on the
# retained user-authority surfaces (Surface 2 — evidence-first gate as
# category-2 deviation-approval; Surface 3 — risk-above-appetite commit
# as category-3 one-time-override).
# ----------------------------------------------------------------------

@test "SKILL.md Step 1 uses fail-fast usage message for malformed args (ADR-044 Surface 1)" {
  # Argument-backfill is typo-class signal, not a decision. Per ADR-044
  # Framework-Mediated boundary + the suite's existing transition-problem
  # / work-problem singular precedent, malformed input fails the contract
  # with a usage block and exits. Re-typing the slash command is faster
  # than the multi-turn AskUserQuestion dialogue that was here before.
  run awk '/^### 1\./,/^### 2\./' "$SKILL_FILE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Usage:"* ]] || [[ "$output" == *"usage message"* ]] || [[ "$output" == *"fail-fast"* ]]
  [[ "$output" == *"exit"* ]] || [[ "$output" == *"stop"* ]]
}

@test "SKILL.md Step 1 does NOT fire AskUserQuestion for argument backfill (regression guard)" {
  # The lazy-deferral surface ADR-044 closed for this skill: per-call
  # AskUserQuestion when args are missing/malformed. If it returns to
  # Step 1, the lazy-count metric (Step 2d) will spike and the skill
  # diverges from transition-problem / work-problem precedent.
  run awk '/^### 1\./,/^### 2\./' "$SKILL_FILE"
  [ "$status" -eq 0 ]
  ! echo "$output" | grep -qE "ask via .?AskUserQuestion|invoke .?AskUserQuestion"
}

@test "SKILL.md Arguments section uses fail-fast (no AskUserQuestion backfill at top of file)" {
  # The original line 20 said "If \$ARGUMENTS is empty or malformed, ask
  # via AskUserQuestion for the incident ID and the action." Replaced
  # with fail-fast pointer to Step 1's usage block. This regression
  # guard catches re-introduction at the Arguments section.
  run awk '/^## Arguments/,/^## Reversible preference/' "$SKILL_FILE"
  [ "$status" -eq 0 ]
  ! echo "$output" | grep -qE "ask via .?AskUserQuestion"
}

@test "SKILL.md Step 3 evidence gate cross-references ADR-044 category-2 (deviation-approval)" {
  # Surface 2 keep: ADR-011's evidence-first rule IS the existing
  # decision; "Record anyway" IS the user-approved deviation; user IS
  # the right authority. The inline ADR-044 cat-2 cross-reference makes
  # the framework-resolution boundary visible at the call site without
  # changing behaviour.
  run awk '/^### 3\./,/^### 4\./' "$SKILL_FILE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"ADR-044"* ]]
  [[ "$output" == *"deviation-approval"* ]] || [[ "$output" == *"category 2"* ]] || [[ "$output" == *"category-2"* ]]
}

@test "SKILL.md Step 8 risk-above-appetite cross-references ADR-044 category-3 (one-time-override)" {
  # Surface 3 keep: in incident-mitigation context the user often wants
  # to ship despite higher risk; the rule (RISK-POLICY appetite) still
  # stands but this specific case warrants an exception. Category-3 is
  # the genuine surface; the cross-ref makes it visible.
  run awk '/^### 8\./,/^### 9\./' "$SKILL_FILE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"ADR-044"* ]]
  [[ "$output" == *"one-time-override"* ]] || [[ "$output" == *"category 3"* ]] || [[ "$output" == *"category-3"* ]]
}

@test "SKILL.md retains AskUserQuestion for Surface 2 evidence-gate + Surface 3 risk-above-appetite (positive guard)" {
  # AskUserQuestion is removed from Surface 1 (Step 1 + Arguments) but
  # MUST remain in Step 3 (evidence gate, ADR-044 cat-2) and Step 8
  # (risk-above-appetite, ADR-044 cat-3). The frontmatter allowed-tools
  # MUST keep AskUserQuestion. Negative-of-negative guard against
  # accidentally over-removing.
  run grep -nE "^allowed-tools:.*AskUserQuestion" "$SKILL_FILE"
  [ "$status" -eq 0 ]
  # Step 3 must still contain AskUserQuestion reference (the evidence
  # gate is the cat-2 surface).
  run awk '/^### 3\./,/^### 4\./' "$SKILL_FILE"
  [ "$status" -eq 0 ]
  echo "$output" | grep -qE "AskUserQuestion"
  # Step 8 must still contain AskUserQuestion reference (risk-above-
  # appetite is the cat-3 surface).
  run awk '/^### 8\./,/^### 9\./' "$SKILL_FILE"
  [ "$status" -eq 0 ]
  echo "$output" | grep -qE "AskUserQuestion"
}

@test "bats file carries the tdd-review: structural-permitted marker (P081 + P136 bridge)" {
  # Per P136 Phase 2 inline plan: bats touched during the audit get
  # the structural-permitted marker as the bridge until P081 Phase 2's
  # canonical retrofit. Without the marker, future TDD agent reviews
  # will flag the file as a P081 violation.
  run grep -nE "tdd-review:[[:space:]]+structural-permitted" "${BATS_TEST_FILENAME}"
  [ "$status" -eq 0 ]
}
