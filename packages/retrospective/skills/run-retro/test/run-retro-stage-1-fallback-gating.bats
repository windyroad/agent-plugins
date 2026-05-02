#!/usr/bin/env bats
#
# P148: run-retro SKILL.md Step 4b Stage 1 MUST carry a tightened
# AFK-branch fallback-gating clause that (a) names `cause: skill_unavailable`
# as the only valid fallback gate, (b) enumerates the rationalisation
# anti-patterns the agent is forbidden to use, and (c) cites the
# advisory script that mechanically enforces the cause allowlist.
#
# # Test shape: minimal structural backstop (ADR-037 permitted exception)
#
# Per P081 (structural-content tests are wasteful — behavioural preferred),
# the LOAD-BEARING test for this fix lives at
# `packages/retrospective/scripts/test/check-tickets-deferred-cause.bats`
# (behavioural — exercises the script against fixture retro summary
# directories with good / bad / legacy / mixed cause column shapes).
#
# This file is a TINY structural backstop that links the SKILL.md prose
# (canonical human-readable source) to the script (mechanical enforcement).
# Without this link, the prose contract and the script contract could
# drift independently — agents reading the prose would see one set of
# valid causes, the script would enforce a different set. The structural
# assertion confirms the prose names the same allowlist token (`skill_unavailable`)
# and the same script path the prose tells the reader to consult.
#
# Architect verdict (2026-04-29): keep the prose as canonical, the
# script as mechanical enforcement, and ONE structural assertion linking
# them. P081 narrows ADR-037's permitted exception; this file's three
# assertions are the architect-approved minimum.
#
# # @adr ADR-037 permitted exception — narrowest justifiable scope.
# # @adr ADR-044 framework-mediated surface boundary cited in SKILL.md.
# # @ticket P148 — Stage 1 fallback-gating tightening (driver).
# # @ticket P145 — sibling defer-pattern at Tier 3 rotation (composing surface).
# # @ticket P081 — behavioural-tests-preferred direction (justifies tiny scope).

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../../.." && pwd)"
  SKILL_MD="$REPO_ROOT/packages/retrospective/skills/run-retro/SKILL.md"
}

@test "Stage 1 AFK branch names 'cause: skill_unavailable' as the only valid fallback gate (P148)" {
  # Links SKILL.md prose to the script's allowlist. If the prose adds
  # a second valid cause without an matching script update, this
  # assertion still passes — the goal is "the prose names the canonical
  # token", not "the prose names the entire allowlist exhaustively".
  run grep -F 'cause: skill_unavailable' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "Stage 1 AFK branch references the advisory script by path (P148)" {
  # Without this reference, a reader of the SKILL.md prose has no path
  # to the mechanical enforcement layer. The script reference IS the
  # affordance to the tooling.
  run grep -F 'check-tickets-deferred-cause.sh' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "Stage 1 AFK branch cites P148 as the anti-pattern driver (P148)" {
  # Audit-trail link: the anti-pattern enumeration's authority is the
  # 2026-04-29 user correction recorded on P148. This assertion confirms
  # the prose names the driver ticket so future readers can locate the
  # evidence trail.
  run grep -F 'P148' "$SKILL_MD"
  [ "$status" -eq 0 ]
}
