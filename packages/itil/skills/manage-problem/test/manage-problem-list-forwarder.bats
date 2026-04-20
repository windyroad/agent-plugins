#!/usr/bin/env bats
# Contract assertions for manage-problem's `list` subcommand forwarder (P071 split slice 1).
#
# Per ADR-010 amended (Skill Granularity section) + P071 phased plan:
# `/wr-itil:manage-problem list` delegates to the new `/wr-itil:list-problems`
# skill via a thin-router forwarder. Original skill carries
# `deprecated-arguments: true` frontmatter; forwarder emits a
# canonical one-line systemMessage deprecation notice.
#
# Structural assertion — Permitted Exception to the source-grep ban
# (ADR-005 / P011 / ADR-037 contract-assertion pattern).
#
# @problem P071
# @jtbd JTBD-001 (enforce governance without slowing down)
# @jtbd JTBD-101 (extend the suite with clear patterns)
#
# Cross-reference:
#   P071: docs/problems/071-argument-based-skill-subcommands-are-not-discoverable.open.md
#   ADR-010 amended — split naming + forwarder contract + deprecated-arguments flag
#   ADR-013 Rule 1 — structured user interaction (forwarder emits systemMessage, not AskUserQuestion)
#   ADR-037 — contract-assertion bats pattern

setup() {
  SKILL_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  SKILL_FILE="${SKILL_DIR}/SKILL.md"
}

@test "manage-problem SKILL.md frontmatter has deprecated-arguments: true (ADR-010 amended)" {
  # ADR-010 amendment pins the frontmatter flag name as `deprecated-arguments`.
  # The host skill of any forwarder route must carry this flag so ADR-037
  # cross-plugin contract assertions can find the opt-in during the
  # deprecation window.
  run grep -nE "^deprecated-arguments:[[:space:]]*true[[:space:]]*$" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "manage-problem Step 1 forwards 'list' argument to /wr-itil:list-problems (P071)" {
  # The forwarder names the target skill explicitly so the router is legible
  # at the contract level. ADR-010's canonical shape: "invokes the new
  # named skill via the Skill tool, not via re-prompting the user".
  run grep -inE "/wr-itil:list-problems" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "manage-problem Step 1 emits the canonical deprecation notice (ADR-010 amended)" {
  # ADR-010's canonical deprecation-notice template:
  # "/wr-<plugin>:<old> <arg> is deprecated; use /wr-<plugin>:<new>
  #  directly. This forwarder will be removed in <plugin>'s next major
  #  version."
  # The notice MUST be emitted as a systemMessage (not AskUserQuestion)
  # because deprecation is informational, not decisional (ADR-013 Rule 1
  # structured-interaction scope).
  run grep -inE "is deprecated.*use /wr-itil:list-problems|deprecated.*list-problems|removed in .* next major version" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "manage-problem Step 1 forwarder does not re-implement the list logic (P071 regression guard)" {
  # The forwarder must not duplicate the list logic — it must delegate.
  # Per ADR-010: "thin-router forwarder re-invokes the new named skill
  # via the Skill tool". If the forwarder grows its own scan logic, the
  # deprecation window will harden into a permanent fork. Guard against
  # this by asserting the forwarder block mentions "delegate" or
  # "Skill tool" language near the list-problems reference.
  run grep -inE "delegate.*list-problems|Skill tool.*list-problems|list-problems.*Skill tool" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}
