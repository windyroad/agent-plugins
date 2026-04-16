#!/usr/bin/env bats
# Doc-lint guard: manage-problem SKILL.md must define the Parked lifecycle
# status and the README.md fast-path cache for the `work` operation.
#
# Structural assertions — Permitted Exception to the source-grep ban (ADR-005 / P011).
# These tests assert that the skill specification document conforms to the
# P027 fix: first-class Parked status + README.md-based WSJF cache.
#
# Cross-reference:
#   P027: docs/problems/027-manage-problem-work-flow-is-expensive.open.md
#   @jtbd JTBD-001 (enforce governance without slowing down — under 60s)
#   @jtbd JTBD-005 (invoke governance assessments on demand)

setup() {
  SKILL_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  SKILL_FILE="${SKILL_DIR}/SKILL.md"
}

# ──────────────────────────────────────────────────────────────────────────────
# Parked lifecycle status
# ──────────────────────────────────────────────────────────────────────────────

@test "SKILL.md lifecycle table includes Parked status" {
  # P027: Parked must be a first-class status so parked problems are
  # auto-excluded from work selection without manual user flags each session.
  run grep -q "Parked" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md defines .parked.md file suffix" {
  # Parked problems need a distinct file suffix so the review step can
  # identify and exclude them by filename pattern alone.
  run grep -q "\.parked\.md" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md excludes parked problems from WSJF ranking" {
  # Parked problems must not appear in the WSJF table — they are listed
  # separately so users can see them but they don't pollute the ranking.
  run grep -q "parked.*exclud\|exclud.*parked\|Parked.*exclud\|exclud.*Parked\|skip.*[Pp]arked\|[Pp]arked.*skip" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

# ──────────────────────────────────────────────────────────────────────────────
# README.md cache (fast-path for `problem work`)
# ──────────────────────────────────────────────────────────────────────────────

@test "SKILL.md references README.md as the cache file" {
  # P027: docs/problems/README.md is the WSJF cache written by review
  # and read by work to skip the full re-scan when nothing changed.
  run grep -q "README\.md" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md describes writing README.md after review" {
  # The review step (9e) must write/overwrite README.md with the ranked table.
  # Without this write, the cache never gets populated.
  run grep -q "README\.md" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md describes checking README.md freshness before full re-scan" {
  # The work fast-path: if README.md is newer than all problem files,
  # skip the 18-file re-scan and read the cached table directly.
  # Proxy: SKILL.md mentions -newer (the find flag used for mtime comparison).
  run grep -q "\-newer" "$SKILL_FILE"
  [ "$status" -eq 0 ]
}
