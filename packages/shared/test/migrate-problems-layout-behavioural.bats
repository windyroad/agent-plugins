#!/usr/bin/env bats

# P170 / RFC-002 / ADR-031 T10: behavioural end-to-end fixture for
# `migrate_problems_to_per_state_layout`. Simulates a flat-layout
# adopter repo in a temp git tree and asserts:
#   1. First invocation migrates every flat ticket into per-state subdirs
#   2. Migration emits a standalone commit with subject + RISK_BYPASS trailer
#   3. Subsequent invocation no-ops (idempotent)
#   4. Partial-migration interruption is recoverable (re-invoke completes)
#   5. detect_flat_layout predicate flips after migration
#   6. Stderr first-fire signal emitted on migration (silent on no-op)
#
# Both manage-problem (T8) and work-problems (T9) source the SAME
# packages/itil/lib/migrate-problems-layout.sh (verbatim sync of the
# canonical packages/shared/lib/ source), so a single behavioural
# fixture against the canonical covers both skill consumer paths per
# the RFC-002 T10 spec. Skill-side STRUCTURAL wiring is asserted at
# packages/itil/skills/manage-problem/test/manage-problem-auto-migrate-step.bats
# and packages/itil/skills/work-problems/test/work-problems-auto-migrate-step.bats.

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../.." && pwd)"
  SHARED_LIB="$REPO_ROOT/packages/shared/lib/migrate-problems-layout.sh"

  # Build an isolated git repo simulating a flat-layout adopter.
  ADOPTER="$(mktemp -d)"
  cd "$ADOPTER"
  git init -q -b main
  git config user.email "test@example.com"
  git config user.name "Test"

  mkdir -p docs/problems
  for n in 001 002 003; do
    cat > "docs/problems/$n-sample-ticket.open.md" <<EOF
# Problem $n: Sample ticket

**Status**: Open
EOF
  done
  cat > "docs/problems/004-sample-ticket.known-error.md" <<EOF
# Problem 004: Known error sample

**Status**: Known Error
EOF
  cat > "docs/problems/005-sample-ticket.verifying.md" <<EOF
# Problem 005: Verifying sample

**Status**: Verification Pending
EOF
  cat > "docs/problems/006-sample-ticket.closed.md" <<EOF
# Problem 006: Closed sample

**Status**: Closed
EOF
  cat > "docs/problems/007-sample-ticket.parked.md" <<EOF
# Problem 007: Parked sample

**Status**: Parked
EOF
  git add docs/problems/
  git -c commit.gpgsign=false commit -q -m "initial flat-layout fixture"
}

teardown() {
  rm -rf "$ADOPTER"
}

@test "behavioural: detect_flat_layout returns 0 on flat-layout fixture" {
  source "$SHARED_LIB"
  run detect_flat_layout "$ADOPTER"
  [ "$status" -eq 0 ]
}

@test "behavioural: first invocation migrates all 7 tickets into per-state subdirs" {
  source "$SHARED_LIB"
  cd "$ADOPTER"
  git config commit.gpgsign false
  run migrate_problems_to_per_state_layout "$ADOPTER"
  [ "$status" -eq 0 ]

  # Per-state subdirs exist
  [ -d "$ADOPTER/docs/problems/open" ]
  [ -d "$ADOPTER/docs/problems/known-error" ]
  [ -d "$ADOPTER/docs/problems/verifying" ]
  [ -d "$ADOPTER/docs/problems/parked" ]
  [ -d "$ADOPTER/docs/problems/closed" ]

  # All flat files relocated
  [ -f "$ADOPTER/docs/problems/open/001-sample-ticket.md" ]
  [ -f "$ADOPTER/docs/problems/open/002-sample-ticket.md" ]
  [ -f "$ADOPTER/docs/problems/open/003-sample-ticket.md" ]
  [ -f "$ADOPTER/docs/problems/known-error/004-sample-ticket.md" ]
  [ -f "$ADOPTER/docs/problems/verifying/005-sample-ticket.md" ]
  [ -f "$ADOPTER/docs/problems/closed/006-sample-ticket.md" ]
  [ -f "$ADOPTER/docs/problems/parked/007-sample-ticket.md" ]

  # Original flat files gone
  ! ls "$ADOPTER"/docs/problems/*.open.md 2>/dev/null
  ! ls "$ADOPTER"/docs/problems/*.known-error.md 2>/dev/null
  ! ls "$ADOPTER"/docs/problems/*.verifying.md 2>/dev/null
  ! ls "$ADOPTER"/docs/problems/*.closed.md 2>/dev/null
  ! ls "$ADOPTER"/docs/problems/*.parked.md 2>/dev/null
}

@test "behavioural: migration emits standalone commit with ADR-031 subject" {
  source "$SHARED_LIB"
  cd "$ADOPTER"
  git config commit.gpgsign false
  migrate_problems_to_per_state_layout "$ADOPTER"

  local subject
  subject=$(git -C "$ADOPTER" log -1 --format=%s)
  [[ "$subject" == *"docs(problems): auto-migrate to per-state subdirectory layout (ADR-031)"* ]]
}

@test "behavioural: migration commit carries RISK_BYPASS: adr-031-migration trailer" {
  source "$SHARED_LIB"
  cd "$ADOPTER"
  git config commit.gpgsign false
  migrate_problems_to_per_state_layout "$ADOPTER"

  local trailer
  trailer=$(git -C "$ADOPTER" log -1 --format=%B | grep -E '^RISK_BYPASS:')
  [[ "$trailer" == "RISK_BYPASS: adr-031-migration" ]]
}

@test "behavioural: migration commit body cites ADR-031 file (JTBD-201 audit-trail)" {
  source "$SHARED_LIB"
  cd "$ADOPTER"
  git config commit.gpgsign false
  migrate_problems_to_per_state_layout "$ADOPTER"

  local body
  body=$(git -C "$ADOPTER" log -1 --format=%B)
  [[ "$body" == *"docs/decisions/031-problem-ticket-directory-layout"* ]]
}

@test "behavioural: subsequent invocation is no-op (idempotent)" {
  source "$SHARED_LIB"
  cd "$ADOPTER"
  git config commit.gpgsign false
  migrate_problems_to_per_state_layout "$ADOPTER"
  local commit_count_after_first
  commit_count_after_first=$(git -C "$ADOPTER" rev-list --count HEAD)

  run migrate_problems_to_per_state_layout "$ADOPTER"
  [ "$status" -eq 0 ]

  local commit_count_after_second
  commit_count_after_second=$(git -C "$ADOPTER" rev-list --count HEAD)
  [ "$commit_count_after_first" -eq "$commit_count_after_second" ]
}

@test "behavioural: detect_flat_layout returns 1 after migration completes" {
  source "$SHARED_LIB"
  cd "$ADOPTER"
  git config commit.gpgsign false
  migrate_problems_to_per_state_layout "$ADOPTER"

  run detect_flat_layout "$ADOPTER"
  [ "$status" -eq 1 ]
}

@test "behavioural: partial-migration recoverable (move one file then re-invoke)" {
  source "$SHARED_LIB"
  cd "$ADOPTER"
  git config commit.gpgsign false

  # Simulate a prior interrupted migration: pre-move ONE file into the
  # per-state subdir layout and commit it. The remaining files stay flat.
  mkdir -p docs/problems/open
  git -C "$ADOPTER" mv docs/problems/001-sample-ticket.open.md docs/problems/open/001-sample-ticket.md
  git -C "$ADOPTER" commit -q -m "partial migration"

  # Re-invoke — routine should complete the remaining moves.
  run migrate_problems_to_per_state_layout "$ADOPTER"
  [ "$status" -eq 0 ]

  # All tickets now in per-state subdirs
  [ -f "$ADOPTER/docs/problems/open/001-sample-ticket.md" ]
  [ -f "$ADOPTER/docs/problems/open/002-sample-ticket.md" ]
  [ -f "$ADOPTER/docs/problems/open/003-sample-ticket.md" ]
  [ -f "$ADOPTER/docs/problems/known-error/004-sample-ticket.md" ]
}

@test "behavioural: stderr first-fire signal emitted on migration (JTBD-006 AFK transparency)" {
  source "$SHARED_LIB"
  cd "$ADOPTER"
  git config commit.gpgsign false

  run migrate_problems_to_per_state_layout "$ADOPTER"
  [ "$status" -eq 0 ]
  [[ "$output" == *"migrate-problems-layout: relocated"* ]]
  [[ "$output" == *"tickets to per-state subdirs"* ]]
  [[ "$output" == *"ADR-031"* ]]
}

@test "behavioural: stderr silent on no-op re-invocation" {
  source "$SHARED_LIB"
  cd "$ADOPTER"
  git config commit.gpgsign false

  migrate_problems_to_per_state_layout "$ADOPTER" 2>/dev/null
  # Second invocation should be silent on stderr — no first-fire signal.
  run migrate_problems_to_per_state_layout "$ADOPTER"
  [ "$status" -eq 0 ]
  [[ "$output" != *"migrate-problems-layout: relocated"* ]]
}

@test "behavioural: routine no-ops cleanly on freshly per-state-layout repo (no flat files at all)" {
  source "$SHARED_LIB"
  local fresh
  fresh="$(mktemp -d)"
  (
    cd "$fresh"
    git init -q -b main
    git config user.email "test@example.com"
    git config user.name "Test"
    git config commit.gpgsign false
    mkdir -p docs/problems/open
    cat > docs/problems/open/100-already-migrated.md <<EOF
# Problem 100: Already migrated

**Status**: Open
EOF
    git add docs/problems/
    git commit -q -m "fresh per-state-layout"
  )
  run migrate_problems_to_per_state_layout "$fresh"
  [ "$status" -eq 0 ]
  # No new commit emitted
  local count
  count=$(git -C "$fresh" rev-list --count HEAD)
  [ "$count" -eq 1 ]
  rm -rf "$fresh"
}
