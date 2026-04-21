#!/usr/bin/env bats
# Contract assertions for /wr-itil:link-incident (P071 split slice 6d).
#
# This skill hosts the "link an incident to a problem" user intent
# previously hidden behind /wr-itil:manage-incident <I> link P<M>. It
# verifies the target problem file exists, then writes (or updates) the
# ## Linked Problem section of the incident file with the problem ID,
# title, and current status.
#
# Structural assertion — Permitted Exception to the source-grep ban
# (ADR-005 / P011 / ADR-037 contract-assertion pattern).
#
# @problem P071
# @jtbd JTBD-001 (enforce governance without slowing down — discoverable surface)
# @jtbd JTBD-101 (extend the suite with clear patterns — one skill per distinct user intent)
# @jtbd JTBD-201 (restore service fast with an audit trail — Linked Problem traceability)
#
# Cross-reference:
#   P071: docs/problems/071-argument-based-skill-subcommands-are-not-discoverable.open.md
#   ADR-010 amended (Skill Granularity section) — split naming + forwarder contract
#   ADR-011 — manage-incident skill-wrapping precedent (Linked Problem section)
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

@test "SKILL.md frontmatter name is wr-itil:link-incident (P071 + ADR-010 amended)" {
  # Split naming convention per ADR-010 amendment: <verb>-<object> pair.
  # The new skill's name must match the phased-landing plan pinned in P071.
  run grep -n "^name: wr-itil:link-incident$" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md frontmatter description names the link intent (P071)" {
  # Description must name "link" and "incident" / "problem" so Claude Code
  # autocomplete surfaces the user intent rather than a generic name.
  run grep -inE "^description:.*link.*(incident|problem)|^description:.*(incident|problem).*link" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md frontmatter allowed-tools grants file-mutation surface (P071 — link requires read + edit)" {
  # link-incident verifies the problem file exists (Read + Glob/Bash),
  # reads the incident file (Read), and writes the Linked Problem
  # section (Edit / Write). No Skill tool (no cross-skill invocation),
  # no AskUserQuestion (both args are data parameters).
  run grep -nE "^allowed-tools:" "$SKILL_FILE"
  [ "$status" -eq 0 ]
  run grep -nE "^allowed-tools:.*Write" "$SKILL_FILE"
  [ "$status" -eq 0 ]
  run grep -nE "^allowed-tools:.*Edit" "$SKILL_FILE"
  [ "$status" -eq 0 ]
  run grep -nE "^allowed-tools:.*Bash" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md documents the P<MMM> problem-file lookup (P071 + ADR-011)" {
  # The link operation verifies docs/problems/P<MMM>-*.md exists before
  # writing the Linked Problem section. The SKILL.md must name the
  # problem-file lookup explicitly so the cross-directory dependency is
  # legible.
  run grep -inE "docs/problems|P<MMM>|P<NNN>|problem file" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md documents the ## Linked Problem section write (P071 + ADR-011)" {
  # The link operation writes (or updates) the ## Linked Problem section
  # with `P<MMM> (<title>) — <status>`. The SKILL.md must name the
  # section explicitly so the audit-trail invariant (JTBD-201) is
  # preserved post-split.
  run grep -inE "Linked Problem" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md documents both data-parameter arguments (P071 — incident ID + problem ID)" {
  # link-incident takes two positional data parameters: the incident ID
  # (I###) and the problem ID (P###). The SKILL.md must document both
  # so the argument shape is legible.
  run grep -inE "I<NNN>|I<###>|incident ID|I007|<I###>" "$SKILL_FILE"
  [ "$status" -eq 0 ]
  run grep -inE "P<MMM>|P<###>|P<NNN>|problem ID" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md cites P071 and ADR-010 amended (P071 + ADR-025)" {
  # ADR-025 inheritance per ADR-037: contract-assertion bats should reflect
  # traceability cites on the skill spec document.
  run grep -inE "P071|ADR-010" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md cites ADR-011 for the Linked Problem section convention (P071 + ADR-011)" {
  # link-incident inherits the Linked Problem section convention from
  # ADR-011. The SKILL.md must cite ADR-011 so the precedent chain is
  # legible.
  run grep -inE "ADR-011" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md does not carry a deprecated-arguments frontmatter flag (clean-split skill)" {
  # link-incident is a clean-split skill with no argument-subcommands
  # itself (its arguments are data parameters — incident ID + problem ID).
  # ADR-010 amendment's `deprecated-arguments: true` flag is only valid
  # on host skills with forwarder routes. link-incident is a forwarder
  # TARGET, not a host. It must NOT carry the flag.
  run grep -E "^deprecated-arguments:" "$SKILL_FILE"
  [ "$status" -ne 0 ]
}

@test "SKILL.md does not use word-argument subcommand branching (P071 regression guard)" {
  # The whole point of P071: Claude Code autocomplete does not surface
  # word-argument subcommands. A clean-split skill must not reintroduce
  # word-arg subcommand routing. The data parameters <I> and <P> are
  # strings, not verb keywords.
  run grep -inE "If arguments start with \"(list|mitigate|restore|close|link)\"|If arguments contain \"(list|mitigate|restore|close|link)\"" "$SKILL_FILE"
  [ "$status" -ne 0 ]
}
