#!/usr/bin/env bats
# Contract assertions for /wr-itil:restore-incident (P071 split slice 6b).
#
# This skill hosts the "mark an incident as restored" user intent previously
# hidden behind /wr-itil:manage-incident <I> restored. It transitions an
# incident from .mitigating.md to .restored.md, updates the Status field,
# appends a "Service restored" timeline entry, and invokes the Skill tool
# to hand off to /wr-itil:manage-problem for linked-problem creation /
# update per ADR-011's Decision Outcome point 4.
#
# Structural assertion — Permitted Exception to the source-grep ban
# (ADR-005 / P011 / ADR-037 contract-assertion pattern).
#
# @problem P071
# @jtbd JTBD-001 (enforce governance without slowing down — discoverable surface)
# @jtbd JTBD-101 (extend the suite with clear patterns — one skill per distinct user intent)
# @jtbd JTBD-201 (restore service fast with an audit trail — this skill IS the active-restoration path)
#
# Cross-reference:
#   P071: docs/problems/071-argument-based-skill-subcommands-are-not-discoverable.open.md
#   ADR-010 amended (Skill Granularity section) — split naming + forwarder contract
#   ADR-011 — manage-incident skill-wrapping precedent (cross-skill Skill-tool invocation to manage-problem)
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

@test "SKILL.md frontmatter name is wr-itil:restore-incident (P071 + ADR-010 amended)" {
  # Split naming convention per ADR-010 amendment: <verb>-<object> pair.
  # The new skill's name must match the phased-landing plan pinned in P071.
  run grep -n "^name: wr-itil:restore-incident$" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md frontmatter description names the restore intent (P071)" {
  # Description must name "restore" and "incident" so Claude Code autocomplete
  # surfaces the user intent rather than a generic name.
  run grep -inE "^description:.*restor.*incident|^description:.*incident.*restor|^description:.*service restored" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md frontmatter allowed-tools grants file-mutation + Skill surface (P071 — restore requires rename + handoff)" {
  # restore-incident renames .mitigating.md → .restored.md, updates the
  # Status field, and invokes /wr-itil:manage-problem via the Skill tool.
  # AskUserQuestion is required for the problem-handoff prompt (yes /
  # no-with-justification) per ADR-011 Decision Outcome point 4.
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
  run grep -nE "^allowed-tools:.*Skill" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md documents the .mitigating.md → .restored.md rename (P071 + ADR-011)" {
  # The restore transition renames the incident file from .mitigating.md
  # to .restored.md. The SKILL.md must name both suffixes explicitly so
  # the file-suffix contract is legible.
  run grep -inE "\.mitigating\.md" "$SKILL_FILE"
  [ "$status" -eq 0 ]
  run grep -inE "\.restored\.md" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md documents the verification-signal pre-flight (P071 + ADR-011)" {
  # Per ADR-011, restore requires at least one recorded mitigation attempt
  # AND a captured verification signal (e.g. "error rate back to baseline
  # per Datadog", "user reports normal", "synthetic probe passing").
  # The SKILL.md must name the verification-signal check explicitly.
  run grep -inE "verification signal|verify|verification" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md documents the manage-problem handoff via the Skill tool (P071 + ADR-011 Decision Outcome 4)" {
  # The restore transition hands off to /wr-itil:manage-problem via the
  # Skill tool so a problem record is created or updated with the timeline
  # summary + top-ranked hypothesis + mitigation + verification signal.
  # The SKILL.md must name the handoff target so the cross-skill
  # invocation is legible.
  run grep -inE "wr-itil:manage-problem|manage-problem" "$SKILL_FILE"
  [ "$status" -eq 0 ]
  run grep -inE "Skill tool|via the Skill" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md documents the 'no problem required' justification path (P071 + ADR-011)" {
  # Per ADR-011, the user may decline problem creation with a documented
  # justification (e.g. "one-off cosmic-bit-flip; not reproducible"). The
  # SKILL.md must document the No Problem section write so the audit
  # trail invariant (JTBD-201) is preserved post-split.
  run grep -inE "No Problem|no problem required|no-problem" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md cites P071 and ADR-010 amended (P071 + ADR-025)" {
  # ADR-025 inheritance per ADR-037: contract-assertion bats should reflect
  # traceability cites on the skill spec document.
  run grep -inE "P071|ADR-010" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md cites ADR-011 for the incident lifecycle conventions (P071 + ADR-011)" {
  # restore-incident inherits file-suffix conventions and the handoff
  # contract from ADR-011. The SKILL.md must cite ADR-011 so the
  # precedent chain is legible.
  run grep -inE "ADR-011" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md does not carry a deprecated-arguments frontmatter flag (clean-split skill)" {
  # restore-incident is a clean-split skill with no argument-subcommands
  # itself (its argument is a data parameter — incident ID only).
  # ADR-010 amendment's `deprecated-arguments: true` flag is only valid
  # on host skills with forwarder routes. restore-incident is a
  # forwarder TARGET, not a host. It must NOT carry the flag.
  run grep -E "^deprecated-arguments:" "$SKILL_FILE"
  [ "$status" -ne 0 ]
}

@test "SKILL.md does not use word-argument subcommand branching (P071 regression guard)" {
  # The whole point of P071: Claude Code autocomplete does not surface
  # word-argument subcommands. A clean-split skill must not reintroduce
  # word-arg subcommand routing (e.g. `list` / `mitigate` / `restore`).
  # The data parameter <I> is a string, not a verb keyword.
  run grep -inE "If arguments start with \"(list|mitigate|restore|close|link)\"|If arguments contain \"(list|mitigate|restore|close|link)\"" "$SKILL_FILE"
  [ "$status" -ne 0 ]
}
