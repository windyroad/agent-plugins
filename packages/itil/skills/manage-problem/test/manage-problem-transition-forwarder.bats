#!/usr/bin/env bats
# Contract assertions for manage-problem's `<NNN> <status>` transition forwarder (P071 split slice 4).
#
# Per ADR-010 amended (Skill Granularity section) + P071 phased plan:
# `/wr-itil:manage-problem <NNN> known-error` (and the sibling close
# form) delegates to the new `/wr-itil:transition-problem` skill via
# a thin-router forwarder. Original skill already carries
# `deprecated-arguments: true` frontmatter from slice 1; this file
# asserts the transition-forwarder-specific contract.
#
# Note on shape: the transition forwarders are the trickiest of the
# P071 phased set because the argument is `<NNN> <word>` (data +
# verb). The parser must route on the PRESENCE of the verb token
# (`known-error` / `verifying` / `close`) AFTER the data parameter
# `<NNN>`. A bare `<NNN>` remains the legitimate update flow — it
# must NOT forward. This test locks the distinction in.
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
#   ADR-022 — Verification Pending is a first-class status; .verifying.md suffix on release
#   ADR-037 — contract-assertion bats pattern

setup() {
  SKILL_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  SKILL_FILE="${SKILL_DIR}/SKILL.md"
}

@test "manage-problem Step 1 forwards '<NNN> known-error' argument to /wr-itil:transition-problem (P071 slice 4)" {
  # The forwarder names the target skill explicitly so the router is
  # legible at the contract level. ADR-010's canonical shape: "invokes
  # the new named skill via the Skill tool, not via re-prompting the
  # user".
  run grep -inE "/wr-itil:transition-problem" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "manage-problem Step 1 emits the canonical known-error transition deprecation notice (ADR-010 amended)" {
  # ADR-010's canonical deprecation-notice template:
  # "/wr-<plugin>:<old> <arg> is deprecated; use /wr-<plugin>:<new>
  #  directly. This forwarder will be removed in <plugin>'s next major
  #  version."
  # The notice MUST be emitted as a systemMessage (not AskUserQuestion)
  # because deprecation is informational, not decisional (ADR-013
  # Rule 1 scope). The transition-forwarder notice is distinct from
  # list + review + work forwarders; all four must co-exist verbatim.
  run grep -inE "is deprecated.*use /wr-itil:transition-problem|deprecated.*transition-problem|removed in .* next major version" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "manage-problem Step 1 transition-forwarder does not re-implement Step 7 transition logic (P071 regression guard)" {
  # The forwarder must not duplicate the transition logic — it must
  # delegate. Per ADR-010: "thin-router forwarder re-invokes the new
  # named skill via the Skill tool". If the forwarder grows its own
  # pre-flight + P057 + P063 + P062 stack, the deprecation window
  # will harden into a permanent fork.
  run grep -inE "delegate.*transition-problem|Skill tool.*transition-problem|transition-problem.*Skill tool" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "manage-problem Step 1 parser distinguishes bare <NNN> (update) from <NNN> <status> (transition)" {
  # Critical safety rule: a bare `<NNN>` argument must REMAIN the
  # update flow — it must not accidentally forward to
  # transition-problem. Only the `<NNN> <status>` shape (where
  # <status> ∈ {known-error, verifying, close}) triggers the
  # transition forwarder. The parser block must name both branches
  # so the distinction is legible at the contract level.
  run grep -inE "known-error|verifying|close" "$SKILL_FILE"
  [ "$status" -eq 0 ]
  # And the bare-NNN update path is still documented.
  run grep -inE "bare .NNN.|update flow|<NNN>.*update" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "manage-problem transition-forwarder covers known-error, verifying, and close (lifecycle completeness)" {
  # ADR-022 codifies three transition destinations: known-error,
  # verifying (Verification Pending), and closed. All three must
  # appear in the forwarder contract so users can rely on the
  # forwarder for the full lifecycle during the deprecation window.
  # Missing any destination would force users back onto inline
  # execution for that one case.
  run grep -inE "known-error" "$SKILL_FILE"
  [ "$status" -eq 0 ]
  run grep -inE "verifying|verification.pending" "$SKILL_FILE"
  [ "$status" -eq 0 ]
  run grep -inE "\bclose\b" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}
