#!/usr/bin/env bats
# Contract assertions for /wr-itil:list-problems (P071 split slice 1).
#
# This skill hosts the "list open and known-error problems" user intent
# previously hidden behind /wr-itil:manage-problem list. It is a pure
# read-only display skill — no branching, no interaction, no file edits.
#
# Structural assertion — Permitted Exception to the source-grep ban
# (ADR-005 / P011 / ADR-037 contract-assertion pattern).
#
# @problem P071
# @jtbd JTBD-001 (enforce governance without slowing down — discoverable surface)
# @jtbd JTBD-101 (extend the suite with clear patterns — one skill per distinct user intent)
#
# Cross-reference:
#   P071: docs/problems/071-argument-based-skill-subcommands-are-not-discoverable.open.md
#   ADR-010 amended (Skill Granularity section) — split naming + forwarder contract
#   ADR-022 — Verification Pending status conventions (list-problems respects `.verifying.md` exclusion)
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

@test "SKILL.md frontmatter name is wr-itil:list-problems (P071 + ADR-010 amended)" {
  # Split naming convention per ADR-010 amendment: <verb>-<object> pair.
  # The new skill's name must match the phased-landing plan pinned in P071.
  run grep -n "^name: wr-itil:list-problems$" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md frontmatter description names the list intent (P071)" {
  # Description must name "list" and "problem" so Claude Code autocomplete
  # surfaces the user intent rather than a generic name.
  run grep -inE "^description:.*list.*problem|^description:.*problem.*list" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md frontmatter allowed-tools is read-only (P071 + architect Q3)" {
  # Architect Q3: pure read-only list display. No Write, no Edit, no
  # AskUserQuestion. This assertion is the enforceable contract — future
  # maintainers cannot accidentally grow the tool surface past the intent.
  run grep -nE "^allowed-tools:" "$SKILL_FILE"
  [ "$status" -eq 0 ]
  run grep -E "^allowed-tools:.*(Write|Edit|AskUserQuestion)" "$SKILL_FILE"
  [ "$status" -ne 0 ]
}

@test "SKILL.md documents the read-only scan scope (P071)" {
  # The skill reads .open.md and .known-error.md files from docs/problems/.
  # .verifying.md and .parked.md are excluded from the dev-work ranking per
  # ADR-022 (Verification Pending) and the Parked-policy; but they MAY be
  # shown in dedicated sections. The SKILL.md must name both `.open.md` and
  # `.known-error.md` glob patterns explicitly so the contract is legible.
  run grep -inE "\.open\.md" "$SKILL_FILE"
  [ "$status" -eq 0 ]
  run grep -inE "\.known-error\.md" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md reuses the git-log freshness check from manage-problem review (P071 + architect Q4)" {
  # Architect Q4: reuse the git-log freshness check from manage-problem
  # review (same skill suite, same cache semantics per P031).
  run grep -inE "git log.*README\.md|readme_commit|git log -1 --format=%H" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md cites P071 and ADR-010 amended (P071 + ADR-025)" {
  # ADR-025 inheritance per ADR-037: contract-assertion bats should reflect
  # traceability cites on the skill spec document.
  run grep -inE "P071|ADR-010" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md does not carry a deprecated-arguments frontmatter flag (clean-split skill)" {
  # Architect advisory: list-problems is a clean-split skill with no
  # argument-subcommands itself. ADR-010 amendment's
  # `deprecated-arguments: true` flag is only valid on host skills with
  # forwarder routes — list-problems is the forwarder TARGET, not the
  # host. It must NOT carry the flag.
  run grep -E "^deprecated-arguments:" "$SKILL_FILE"
  [ "$status" -ne 0 ]
}

@test "SKILL.md does not use word-argument subcommand branching (P071 regression guard)" {
  # The whole point of P071: Claude Code autocomplete does not surface
  # arguments. A clean-split skill must not reintroduce word-arg subcommand
  # routing. The SKILL.md must not contain `If arguments start with "list"`
  # / `If arguments contain "work"` / etc. patterns.
  run grep -inE "If arguments start with|If arguments contain" "$SKILL_FILE"
  [ "$status" -ne 0 ]
}
