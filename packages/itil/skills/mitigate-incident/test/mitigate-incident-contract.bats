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
# @problem P071
# @jtbd JTBD-001 (enforce governance without slowing down — discoverable surface)
# @jtbd JTBD-101 (extend the suite with clear patterns — one skill per distinct user intent)
# @jtbd JTBD-201 (restore service fast with an audit trail — mitigation + evidence gate)
#
# Cross-reference:
#   P071: docs/problems/071-argument-based-skill-subcommands-are-not-discoverable.open.md
#   ADR-010 amended (Skill Granularity section) — split naming + forwarder contract
#   ADR-011 — manage-incident skill-wrapping precedent (evidence-gate, reversible preference)
#   ADR-037 — contract-assertion bats pattern

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
