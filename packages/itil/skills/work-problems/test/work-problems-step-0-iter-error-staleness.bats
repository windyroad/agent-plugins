#!/usr/bin/env bats
# Contract-assertion bats for work-problems Step 0 session-continuity
# detection — staleness filter on .afk-run-state/iter-*.json error markers
# (per P333).
#
# Per ADR-037 SKILL.md is a contract document; these assertions check the
# contract strings the skill prose authoritatively pins for the staleness
# filter that distinguishes load-bearing partial-work markers from stale
# residuals. Companion to work-problems-preflight-session-continuity.bats
# (which covers the broader signal-enumeration + interactive/AFK routing
# invariants from P109).
#
# Cross-reference:
#   @problem P333 (Step 0 session-continuity has no staleness filter on
#                  .afk-run-state/iter-*.json error markers — stale residuals
#                  indefinitely false-positive the halt/ask gate)
#   @problem P109 (parent session-continuity detection extension)
#   ADR-019 (AFK orchestrator preflight — extension surface)
#   ADR-032 (subprocess artefact contract — iter-*.json shape)
#   ADR-037 (skill testing strategy — contract-assertion framing)
#   @jtbd JTBD-006 (Progress the Backlog While I'm Away — false-positive
#                   halts violate the AFK forward-progress outcome)

setup() {
  SKILL_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  SKILL_FILE="${SKILL_DIR}/SKILL.md"
}

@test "SKILL.md exists" {
  [ -f "$SKILL_FILE" ]
}

@test "SKILL.md Step 0 cites P333 as the staleness-filter driver" {
  # Contract criterion: the staleness predicate is traceable to its
  # driver ticket so a reader can find the failure mode the filter
  # closes.
  run grep -nE "P333" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md Step 0 names the staleness filter for iter-*.json markers" {
  # Contract criterion: the iter-*.json error-marker row names a
  # staleness / freshness predicate (not merely the is_error /
  # api_error_status field check).
  run grep -niE "stale|staleness|freshness|fresh per" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md Step 0 names mtime + HEAD-commit-time as the staleness primitive" {
  # Contract criterion: the staleness predicate is specified as mtime
  # vs HEAD-commit-time (the engineering primitive). The "more
  # permissive of two" disjunction is asserted in a sibling test below.
  run grep -niE "mtime" "$SKILL_FILE"
  [ "$status" -eq 0 ]
  run grep -niE "HEAD.commit|HEAD's commit|commit.time" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md Step 0 names the 24h fallback for the staleness predicate" {
  # Contract criterion: the "OR within 24h" disjunction protects the
  # fresh-repo-no-commits-since-marker edge case.
  run grep -niE "24h|24 hour|last 24" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md Step 0 names the silent-skip directive for stale residuals" {
  # Contract criterion: the action on stale-classified markers is
  # silent-skip, not halt-with-report. This is the directional
  # asymmetry the contract pins (fresh = halt, stale = skip).
  run grep -niE "skip.*silent|silently.*skip|silent skip" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md Step 0 retains the is_error / api_error_status field names alongside the staleness filter" {
  # Contract criterion: the existing P109 signal field-name contract
  # MUST coexist with the new staleness predicate — the staleness
  # filter narrows the load-bearing signal, it does not replace the
  # field check.
  run grep -niE "is_error.*true|api_error_status" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md Step 0 names the iter-summary annotation for skipped stale markers" {
  # Contract criterion per JTBD-006 audit-trail outcome (line 34 of
  # docs/jtbd/developer/JTBD-006.md): "every action taken during AFK
  # mode should be traceable via git history and the progress
  # summary". A silent-skip without an iter-summary annotation drops
  # an action from the audit trail; the contract names the annotation
  # shape so a stale-skipped-but-actually-load-bearing marker is
  # recoverable on user return.
  run grep -niE "stale iter.error|stale.*marker.*skip|iter.error.markers? skipped" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}
