#!/usr/bin/env bats
# Contract assertions for /wr-itil:close-incident (P071 split slice 6c).
#
# This skill hosts the "close a restored incident" user intent previously
# hidden behind /wr-itil:manage-incident <I> close. It checks the Linked
# Problem's file suffix and, if the problem is in an acceptable terminal
# state (.known-error.md / .verifying.md / .closed.md) OR the incident
# documents a No Problem justification, renames the incident file from
# .restored.md to .closed.md and updates the Status field.
#
# Structural assertion — Permitted Exception to the source-grep ban
# (ADR-005 / P011 / ADR-037 contract-assertion pattern).
#
# @problem P071
# @jtbd JTBD-001 (enforce governance without slowing down — discoverable surface)
# @jtbd JTBD-101 (extend the suite with clear patterns — one skill per distinct user intent)
# @jtbd JTBD-201 (restore service fast with an audit trail — close gate preserves the problem-handoff link)
#
# Cross-reference:
#   P071: docs/problems/071-argument-based-skill-subcommands-are-not-discoverable.open.md
#   ADR-010 amended (Skill Granularity section) — split naming + forwarder contract
#   ADR-011 — manage-incident skill-wrapping precedent (close gate on linked problem)
#   ADR-022 — problem lifecycle verification-pending status (.verifying.md accepted alongside .known-error.md / .closed.md)
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

@test "SKILL.md frontmatter name is wr-itil:close-incident (P071 + ADR-010 amended)" {
  # Split naming convention per ADR-010 amendment: <verb>-<object> pair.
  # The new skill's name must match the phased-landing plan pinned in P071.
  run grep -n "^name: wr-itil:close-incident$" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md frontmatter description names the close intent (P071)" {
  # Description must name "close" and "incident" so Claude Code autocomplete
  # surfaces the user intent rather than a generic name.
  run grep -inE "^description:.*clos.*incident|^description:.*incident.*clos" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md frontmatter allowed-tools grants file-mutation surface (P071 — close requires rename + edit)" {
  # close-incident renames .restored.md → .closed.md and updates the
  # Status field. Unlike restore-incident, the linked-problem gate is a
  # hard check (not a prompt), so no AskUserQuestion is required. No
  # cross-skill invocation either, so no Skill tool is required.
  run grep -nE "^allowed-tools:" "$SKILL_FILE"
  [ "$status" -eq 0 ]
  run grep -nE "^allowed-tools:.*Write" "$SKILL_FILE"
  [ "$status" -eq 0 ]
  run grep -nE "^allowed-tools:.*Edit" "$SKILL_FILE"
  [ "$status" -eq 0 ]
  run grep -nE "^allowed-tools:.*Bash" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md documents the .restored.md → .closed.md rename (P071 + ADR-011)" {
  # The close transition renames the incident file from .restored.md
  # to .closed.md. The SKILL.md must name both suffixes explicitly so
  # the file-suffix contract is legible.
  run grep -inE "\.restored\.md" "$SKILL_FILE"
  [ "$status" -eq 0 ]
  run grep -inE "\.closed\.md" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md documents the Linked-Problem gate with .known-error.md allowance (P071 + ADR-011)" {
  # Per ADR-011, the close gate accepts a linked problem in
  # .known-error.md state. Older form of the gate — must still be
  # named explicitly post-ADR-022.
  run grep -inE "known-error" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md documents the Linked-Problem gate .verifying.md allowance (P071 + ADR-022)" {
  # Per ADR-022, .verifying.md (fix released, root cause confirmed,
  # awaiting verification) also satisfies the incident-close gate.
  # The SKILL.md must name this allowance explicitly so the ADR-022
  # extension is preserved post-split.
  run grep -inE "\.verifying\.md|verifying" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md documents the No Problem justification path (P071 + ADR-011)" {
  # Per ADR-011, the incident may carry a ## No Problem section with a
  # justification (e.g. "one-off cosmic-bit-flip"). In that case the
  # linked-problem gate is bypassed. The SKILL.md must document the
  # No Problem acceptance so the audit trail invariant is preserved.
  run grep -inE "No Problem|no problem" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md documents the .open.md block condition (P071 + ADR-011)" {
  # Per ADR-011, a linked problem in .open.md state blocks the close.
  # The user must transition the problem to Known Error (or the
  # verification pipeline must complete) before the incident can close.
  # The SKILL.md must name this blocking condition explicitly.
  run grep -inE "\.open\.md|Open" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md cites P071 and ADR-010 amended (P071 + ADR-025)" {
  # ADR-025 inheritance per ADR-037: contract-assertion bats should reflect
  # traceability cites on the skill spec document.
  run grep -inE "P071|ADR-010" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md cites ADR-011 + ADR-022 for the close gate (P071 + ADR-011 + ADR-022)" {
  # close-incident inherits the Linked-Problem gate from ADR-011 and the
  # .verifying.md extension from ADR-022. Both must be cited so the
  # precedent chain is legible.
  run grep -inE "ADR-011" "$SKILL_FILE"
  [ "$status" -eq 0 ]
  run grep -inE "ADR-022" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md does not carry a deprecated-arguments frontmatter flag (clean-split skill)" {
  # close-incident is a clean-split skill with no argument-subcommands
  # itself (its argument is a data parameter — incident ID only).
  # ADR-010 amendment's `deprecated-arguments: true` flag is only valid
  # on host skills with forwarder routes. close-incident is a
  # forwarder TARGET, not a host. It must NOT carry the flag.
  run grep -E "^deprecated-arguments:" "$SKILL_FILE"
  [ "$status" -ne 0 ]
}

@test "SKILL.md does not use word-argument subcommand branching (P071 regression guard)" {
  # The whole point of P071: Claude Code autocomplete does not surface
  # word-argument subcommands. A clean-split skill must not reintroduce
  # word-arg subcommand routing. The data parameter <I> is a string,
  # not a verb keyword.
  run grep -inE "If arguments start with \"(list|mitigate|restore|close|link)\"|If arguments contain \"(list|mitigate|restore|close|link)\"" "$SKILL_FILE"
  [ "$status" -ne 0 ]
}
