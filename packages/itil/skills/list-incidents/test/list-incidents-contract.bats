#!/usr/bin/env bats
# Contract assertions for /wr-itil:list-incidents (P071 split slice 5).
#
# This skill hosts the "list active incidents" user intent previously
# hidden behind /wr-itil:manage-incident list. It is a pure read-only
# display skill — no branching, no interaction, no file edits.
#
# Structural assertion — Permitted Exception to the source-grep ban
# (ADR-005 / P011 / ADR-037 contract-assertion pattern).
#
# @problem P071
# @jtbd JTBD-001 (enforce governance without slowing down — discoverable surface)
# @jtbd JTBD-101 (extend the suite with clear patterns — one skill per distinct user intent)
# @jtbd JTBD-201 (restore service fast with an audit trail — incident status visibility)
#
# Cross-reference:
#   P071: docs/problems/071-argument-based-skill-subcommands-are-not-discoverable.open.md
#   ADR-010 amended (Skill Granularity section) — split naming + forwarder contract
#   ADR-011 — manage-incident skill-wrapping precedent (list-incidents mirrors its file conventions)
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

@test "SKILL.md frontmatter name is wr-itil:list-incidents (P071 + ADR-010 amended)" {
  # Split naming convention per ADR-010 amendment: <verb>-<object> pair.
  # The new skill's name must match the phased-landing plan pinned in P071.
  run grep -n "^name: wr-itil:list-incidents$" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md frontmatter description names the list intent (P071)" {
  # Description must name "list" and "incident" so Claude Code autocomplete
  # surfaces the user intent rather than a generic name.
  run grep -inE "^description:.*list.*incident|^description:.*incident.*list" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md frontmatter allowed-tools is read-only (P071 — read-only list display)" {
  # Pure read-only list display (mirrors list-problems slice 1). No Write,
  # no Edit, no AskUserQuestion. This assertion is the enforceable contract —
  # future maintainers cannot accidentally grow the tool surface past the
  # intent.
  run grep -nE "^allowed-tools:" "$SKILL_FILE"
  [ "$status" -eq 0 ]
  run grep -E "^allowed-tools:.*(Write|Edit|AskUserQuestion)" "$SKILL_FILE"
  [ "$status" -ne 0 ]
}

@test "SKILL.md documents the read-only scan scope (P071 + ADR-011)" {
  # The skill reads the three active incident statuses per ADR-011:
  # .investigating.md, .mitigating.md, and .restored.md. Closed incidents
  # are omitted (the view is active backlog, not archive). The SKILL.md
  # must name all three glob patterns explicitly so the contract is
  # legible.
  run grep -inE "\.investigating\.md" "$SKILL_FILE"
  [ "$status" -eq 0 ]
  run grep -inE "\.mitigating\.md" "$SKILL_FILE"
  [ "$status" -eq 0 ]
  run grep -inE "\.restored\.md" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md documents severity-sorted output (P071 + ADR-011)" {
  # Unlike list-problems (WSJF-sorted), list-incidents is severity-sorted
  # per ADR-011 "Severity, not WSJF" — incidents are time-bound events
  # where effort divisor is meaningless. The SKILL.md must name severity
  # as the sort key.
  run grep -inE "severity" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md cites P071 and ADR-010 amended (P071 + ADR-025)" {
  # ADR-025 inheritance per ADR-037: contract-assertion bats should reflect
  # traceability cites on the skill spec document.
  run grep -inE "P071|ADR-010" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md does not carry a deprecated-arguments frontmatter flag (clean-split skill)" {
  # list-incidents is a clean-split skill with no argument-subcommands
  # itself. ADR-010 amendment's `deprecated-arguments: true` flag is only
  # valid on host skills with forwarder routes — list-incidents is the
  # forwarder TARGET, not the host. It must NOT carry the flag.
  run grep -E "^deprecated-arguments:" "$SKILL_FILE"
  [ "$status" -ne 0 ]
}

@test "SKILL.md does not use word-argument subcommand branching (P071 regression guard)" {
  # The whole point of P071: Claude Code autocomplete does not surface
  # arguments. A clean-split skill must not reintroduce word-arg subcommand
  # routing. The SKILL.md must not contain `If arguments start with "list"`
  # / `If arguments contain "mitigate"` / etc. patterns.
  run grep -inE "If arguments start with|If arguments contain" "$SKILL_FILE"
  [ "$status" -ne 0 ]
}

@test "SKILL.md documents the ownership boundary — no README rewrite (P071)" {
  # list-incidents displays active incidents but does NOT maintain a README
  # cache (unlike list-problems which reads a README written by review-problems).
  # For incidents, there is no README cache — the skill always runs a live
  # scan. The SKILL.md must explicitly name the "read-only / no-edit" stance
  # so the ownership boundary is legible to future maintainers.
  run grep -inE "read-only|does not (edit|modify|rewrite|commit)" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}
